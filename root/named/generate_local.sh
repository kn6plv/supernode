#! /bin/bash

(inotifywait --quiet --monitor /tmp/bind/zones --event close_write | while read event do
  cat > /tmp/bind/local.zone.db << __EOF__
;
; This defines the top level local.mesh.
;
\$TTL 60
\$ORIGIN local.mesh.
@  SOA ns.local.mesh. master.local.mesh. (
  $(date +%s) ; Serial
  3600        ; Refresh
  300         ; Retry
  604800      ; Expire
  60 )        ; TTL
;
; Delegate subdomains to relevant name servers
;
      NS  ns0
ns0   A   ${PRIMARY_IP}
local NS  ns0
__EOF__
  for f in /tmp/bind/zones/master-*.zone.db /tmp/bind/zones/slave-*.zone.db
  do
    cat ${f} | grep "10\." >> /tmp/bind/local.zone.db
  done
  #
  # Reload the zone
  #
  rndc reload local.mesh
done) &
