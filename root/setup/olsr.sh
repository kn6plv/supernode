# Generate OLSR

OLSRD_CONFIG="/etc/olsrd/olsrd.conf"

#
# Create the essential OLSRD configuration
#
cat > ${OLSRD_CONFIG} << __EOF__
DebugLevel 0
AllowNoInt yes
IpVersion 4
LinkQualityAlgorithm "etx_ffeth"

MainIp ${PRIMARY_IP}

RtTable 30
RtTableDefault 31

Willingness 7

Hna4
{
__EOF__

if [[ "${MESH_NETS}" != "" && "${DISABLE_SUPERNODE}" != "true" ]]; then
  echo "  10.0.0.0   255.128.0.0" >> ${OLSRD_CONFIG}
  echo "  10.128.0.0 255.128.0.0" >> ${OLSRD_CONFIG}
fi

# Add tunnel IPs so we can be routed to
for tun in {0..31}
do
  vtunr="TUN${tun}"
  vtun=${!vtunr}
  if [ "${vtun}" = "" ]; then
    continue
  fi

  net=$(echo ${vtun} | cut -d: -f 3)
  target=$(echo ${vtun} | cut -d: -f 4)

  # Generate local and remote IPs from network address
  s=($(echo ${net} | tr "." "\n"))
  localip="${s[0]}.${s[1]}.${s[2]}.$((1 + ${s[3]}))"
  remoteip="${s[0]}.${s[1]}.${s[2]}.$((2 + ${s[3]}))"

  if [ "${target}" = "" ]; then
    echo "  ${remoteip} 255.255.255.255" >> ${OLSRD_CONFIG}
  else
    echo "  ${localip} 255.255.255.255" >> ${OLSRD_CONFIG}
  fi
done

cat >> ${OLSRD_CONFIG} << __EOF__
}

LoadPlugin "olsrd_httpinfo.so.0.1"
{
  PlParam "Port" "8081"
  PlParam "Host" "0.0.0.0"
  PlParam "Net" "0.0.0.0 0.0.0.0"
}

LoadPlugin "olsrd_arprefresh.so.0.1"
{
}

LoadPlugin "olsrd_nameservice.so.0.4"
{
  PlParam "name" "${NODE_NAME}"
  PlParam "name-change-script" "/named/generate_zone.sh"
}
__EOF__

#
# Add isolated network connections
#
for net in ${MESH_NETS}
do
  cat >> ${OLSRD_CONFIG} << __EOF__

Interface "${net}"
{
  Mode "isolated"
  $([[ "${net}" == tun* ]] && echo "Ip4Broadcast 255.255.255.255")
  HnaInterval 1.0
  HnaValidityTime 600.0
}
__EOF__
done

#
# Add connections to rest of supernodes
#
for net in ${SUPERNODE_NETS}
do
  cat >> ${OLSRD_CONFIG} << __EOF__

Interface "${net}"
{
  Mode "ether"
  $([[ "${net}" == tun* ]] && echo "Ip4Broadcast 255.255.255.255")
}
__EOF__
done

# Setup routing
ip rule add pref 30220 lookup 30
ip rule add pref 30230 lookup main
ip rule add pref 30240 lookup 31

olsrd
