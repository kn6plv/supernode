#! /bin/bash

trap "killall sleep olsrd named vtund; exit" TERM INT

# Read the config from a file (if it exists) otherwise expect it
# defined in the environment.
if [ -f /config ]; then
 . /config
else
  cat > /config << __EOF__
PRIMARY_IP="${PRIMARY_IP}
DNS_ZONE="${DNS_ZONE}"
__EOF__
fi

# Simple sanity checks.
if [ "${PRIMARY_IP}" = "" ]; then
  echo "PRIMARY_IP is not defined; the primary IPv4 address of this node."
  exit 1
fi
if [ "${DNS_ZONE}" = "" ]; then
  echo "DNS_ZONE is not defined; DNS will not start."
fi
if [ "${NODE_NAME}" = "" ]; then
  echo "NODE_NAME is not defined; the name of this node in the mesh network."
  exit 1
fi
if [ "${MESH_NETS}" = "" -a "${SUPERNODE_NETS}" = "" ]; then
  echo "Neither MESH_NETS or SUPERNODE_NETS are defined. We cannot connect to a network."
  exit 1
fi

# Override the nameserver (just in case)
cat > /etc/resolv.conf << __EOF__
nameserver 1.1.1.1
__EOF__

. /setup-vtun.sh
. /setup-olsr.sh
. /setup-named.sh

sleep 2147483647d &
wait "$!"
