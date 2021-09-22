# Network

# Override the nameserver (just in case)
cat > /etc/resolv.conf << __EOF__
nameserver 1.1.1.1
__EOF__

# Create a dummy interface we can put our PRIMARY_IP on
ip link add link eth0 name primary type vlan id 3072
ifconfig primary ${PRIMARY_IP} netmask 255.0.0.0 broadcast 10.255.255.255
