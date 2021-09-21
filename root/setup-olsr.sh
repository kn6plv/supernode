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
  $([[ "${MESH_NETS}" != "" ]] && echo "10.0.0.0 255.0.0.0")
}

LoadPlugin "olsrd_httpinfo.so.0.1"
{
  PlParam "Port" "8081"
  PlParam "Host" "0.0.0.0"
  PlParam "Net" "0.0.0.0 0.0.0.0"
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

olsrd
