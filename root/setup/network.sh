# Network

IPTABLES=iptables-legacy

# Override the nameserver (just in case)
cat > /etc/resolv.conf << __EOF__
nameserver 1.1.1.1
__EOF__

if [ "${__DEFAULT_INTERFACE_IP}" != "${PRIMARY_IP}" -a "${__SECONDARY_INTERFACE_IP}" != "${PRIMARY_IP}" ]; then
  # Create a dummy interface we can put our PRIMARY_IP on
  ip link add link eth0 name primary type vlan id 3072
  ip addr add ${PRIMARY_IP}/8 broadcast + dev primary
  ip link set primary up
fi

# Enable masquarading on isolated interfaces, so we hide the connected network details from the mesh
if [ "${ENABLE_MASQUARADE}" = "true" ]; then
  for net in ${MESH_NETS}
  do
    ${IPTABLES} -t nat -I POSTROUTING -o ${net} -j SNAT --to-source ${PRIMARY_IP}
  done
fi
