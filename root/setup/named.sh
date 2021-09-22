# Setup NAMED

if [ "${DNS_ZONE}" = "" ]; then
  echo "No DNS_ZONE defined - named not started"
  return
fi

mkdir -p /tmp/bind/master /tmp/bind/slave

CONF=/etc/bind/named.conf.local

# Setup permissions
echo 'acl "othernodes" {' > ${CONF}
for node in ${DNS_SUPERNODES}
do
  ips=$(echo $node | cut -d: -f 2- | tr ":" ";")
  echo "  ${ips};" >> ${CONF}
done
echo '};' >> ${CONF}
echo 'masters "othernodes" {' > ${CONF}
for node in ${DNS_SUPERNODES}
do
  ips=$(echo $node | cut -d: -f 2- | tr ":" ";")
  echo "  ${ips};" >> ${CONF}
done
echo '};' >> ${CONF}

# Add master zones
cat >> ${CONF} << __EOF__
zone "mesh" {
  type master;
  file "/tmp/bind/master/mesh.zone.db";
};
zone "${DNS_ZONE}.mesh" {
  type master;
  also-notify { othernodes; };
  allow-transfer { othernodes; };
  file "/tmp/bind/master/${DNS_ZONE}.zone.db";
};
__EOF__

# Add slaves
for node in ${DNS_SUPERNODES}
do
  zone=$(echo $node | cut -d: -f 1)
  ips=$(echo $node | cut -d: -f 2- | tr ":" ";")
  cat >> ${CONF} << __EOF__
zone "${zone}.mesh" {
  type slave;
  masters { ${ips}; };
  allow-notify { ${ips}; };
  masterfile-format text;
  file "/tmp/bind/slave/${zone}.zone.db";
};
__EOF__
done

# Create master zones
cat > /tmp/bind/master/mesh.zone.db << __EOF__
;
; This defines the top level .mesh and all the nameservers for the subdomains.
; Each mesh will have one subdomain and one or more name servers.
;
\$TTL 60
\$ORIGIN mesh.
@ IN  SOA ns.mesh. master.mesh. (
  $(date +%s) ; Serial
  3600        ; Refresh
  300         ; Retry
  604800      ; Expire
  60 )        ; TTL

;
; Delegate subdomains to relevant name servers
;

          IN NS ns0.${DNS_ZONE}
ns0.${DNS_ZONE} IN A  ${PRIMARY_IP}
${DNS_ZONE}     IN NS ns0.${DNS_ZONE}
__EOF__

for node in ${DNS_SUPERNODES}
do
  zone=$(echo $node | cut -d: -f 1)
  ips=$(echo $node | cut -d: -f 2- | tr ":" "\n")
  count=0
  for ip in $ips
  do
    cat >> /etc/bind/mesh.zone.db << __EOF__
          IN NS ns${count}.${zone}
ns${count}.${zone}  IN A  ${ip}
${zone}     IN NS ns${count}.${zone}
__EOF__
    count=$((count + 1))
  done
done

cat > /tmp/bind/master/${DNS_ZONE}.zone.db << __EOF__
\$TTL 60
\$ORIGIN ${DNS_ZONE}.mesh.
@   IN SOA  dns0.${DNS_ZONE}.mesh. root.${DNS_ZONE}.mesh. (
  $(date +%s) ; Serial
  3600 ; Refresh
  300 ; Retry
  604800 ; Expire
  60 ) ; TTL
;
@           IN NS dns0
dns0        IN A  ${PRIMARY_IP}
${NODE_NAME} IN A  ${PRIMARY_IP}
__EOF__

# Fix rndc.key
chmod 644 /etc/bind/rndc.key

named
