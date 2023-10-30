#!/bin/bash

MAXTUNNEL="${MAXTUNNEL:-31}"

# Generate VTUN client

mkdir /dev/net
mknod -m 666 /dev/net/tun c 10 200

cat > /etc/vtund.conf << __EOF__
options {
  port 5525;
  ifconfig /sbin/ifconfig;
  route /sbin/route;
}
default {
  keepalive yes;
  persist keep;
}
__EOF__

#
# Loop through set of TUN0 to TUN31 variables, creating a tunnel for each valid one.
#
for tun in {0..${MAXTUNNEL}}
do
  vtunr="TUN${tun}"
  vtun=${!vtunr}
  if [ "${vtun}" = "" ]; then
    continue
  fi

  name=$(echo "${vtun}" | cut -d: -f 1)
  password=$(echo "${vtun}" | cut -d: -f 2)
  net=$(echo "${vtun}" | cut -d: -f 3)
  target=$(echo "${vtun}" | cut -d: -f 4)

  # Ignore incomplete entries
  if [ "${name}" = "" ] || [ "${password}" = "" ] || [ "${net}" = "" ]; then
    continue
  fi

  # Generate local and remote IPs from network address
  mapfile -t s < <(echo "${net}" | tr "." "\n")
  localip="${s[0]}.${s[1]}.${s[2]}.$((1 + s[3]))"
  remoteip="${s[0]}.${s[1]}.${s[2]}.$((2 + s[3]))"

  if [ "${target}" = "" ]; then
    # Server config
    myip="${remoteip}"
    farip="${localip}"
  else
    # Client config
    myip="${localip}"
    farip="${remoteip}"
  fi

  cat >> /etc/vtund.conf << __EOF__
${name}-${s[0]}-${s[1]}-${s[2]}-${s[3]} {
  device tun${tun};
  passwd ${password};
  up {
    ifconfig "%% ${myip} netmask 255.255.255.252 pointopoint ${farip} mtu 1450";
    route "add -net ${net}/30 gw ${farip}";
  };
}
__EOF__

  tun=$((tun + 1))
done
