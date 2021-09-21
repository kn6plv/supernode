AREDN Supernode
===

AREDN Supernodes provide a mechanism to connect multiple AREDN meshes together, allowing traffic to travel between them, without implicityly advertising all the nodes in every mesh to every other mesh. For a more complete description of why this is useful and how it works see https://docs.google.com/document/d/1Gqkv2wF6M7szCfbdVPbEG7IQzjDebQqdRx6mfLGMOqE/edit?usp=sharing

Configuration
---

For easy of use, a supernode is contained in a Docker container which can be configured using a number of environmental variables:

* *NODE_NAME* - This is the name for this supernode, and will be the name visible on the AREDN mesh this node directly connects to.

* *PRIMARY_IP* - This is the primary IPv4 address for this node and should match the IP address on a network connection to a mesh.
* *DNS_ZONE* - This is the DNS zone name for the connected mesh. Locally all AREDN networks have the zone name __local__ and domain suffix __local.mesh__. This is the global zone name (e.g. __sfwem__).
* *DNS_SUPERNODE* - The DNS information to connect this supernode to the DNS servers of other supernodes for other meshes.  This is formatted as __zone:ipaddress__ space seperated pairs (e.g. __socalnet:1.2.3.4__ __aznet:5.6.7.8__)
* *MESH_NETS* - List of network devices which are used to connect this supernode to a single mesh.
* *SUPERNODE_NETS* - List of network devices which are used to connect this supernode to other supernodes.
* *TUN0, TUN1, ... TUN31* - Each TUNx can be used to configure a vtund client or server to connect this supernode to other supernodes or a mesh network. Each configuration takes four parameters, seperated by colons, and follow AREDN naming and network convensions. For example __KN6PLV-SFMON:apassword:172.32.90.240:tunnels.xojs.org__ defines a tunnel named __KN6PLV-SFMON__ with a password __apassword__. The tunnel uses __172.32.90.240__ as its network, and connects to the tunnel server __tunnels.xojs.org__. If the tunnel server parameter is omitted, this supernode will instead create a tunnel server for another client to connect to.

Running the Docker
---

...
