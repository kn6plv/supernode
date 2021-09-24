#! /bin/bash

CONF=/tmp/bind/local.zone.db

update_local() {
  cat > ${CONF} << __EOF__
\$TTL 60
\$ORIGIN local.mesh.
@  SOA ns.local.mesh. master.local.mesh. (
  $(date +%s) ; Serial
  3600        ; Refresh
  300         ; Retry
  604800      ; Expire
  60 )        ; TTL

      NS  ns0
ns0   A   ${PRIMARY_IP}
local NS  ns0
__EOF__
  for f in /tmp/bind/zones/master-*.zone.db /tmp/bind/zones/slave-*.zone.db
  do
    cat ${f} | grep "10\." >> ${CONF}
  done
  if [ "${LOCALNODE}" != "" ]; then
    echo "localnode CNAME ${LOCALNODE}" >> ${CONF}
  fi
  #
  # Reload the zone
  #
  rndc reload local.mesh
}

(inotifywait --quiet --monitor /tmp/bind/zones --event close_write | while read event
do
  update_local
done) &
