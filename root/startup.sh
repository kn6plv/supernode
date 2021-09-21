# /bin/bash

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
  echo "PRIMARY_IP is not defined. The primary IPv4 address of this node."
  exit 1
fi
if [ "${DNS_ZONE}" = "" ]; then
  echo "DNS_ZONE is not defined. The dns zone name for the connected mesh."
  exit 1
fi
if [ "${NODE_NAME}" = "" ]; then
  echo "NODE_NAME is not defined. The name of this supernode in the mesh network"
  exit 1
fi
if [ "${ISOLATED_NETS}" = "" ]; then
  echo "ISOLATED_NETS is not defined. These aere the network device which connect this supernode to a mesh."
  exit 1
fi
if [ "${SUPERNODE_NETS}" = "" ]; then
  echo "SUPERNODE_NETS is not defined. These are the network devices which connect this supernode to others."
  exit 1
fi

. /setup-vtun.sh
. /setup-olsr.sh
. /setup-named.sh

sleep 2147483647d &
wait "$!"
