FROM debian:stable-20210902-slim AS build

RUN apt update ;\
    apt install -y git build-essential bison flex libgps-dev vtun bind9 iptables inotify-tools net-tools dnsutils procps

RUN mkdir build ;\
    cd build ;\
    git clone --depth 1 https://github.com/kn6plv/olsrd.git ;\
    cd olsrd ;\
    make build_all ;\
    make install_all ;\
    cd / ;\
    rm -rf build

FROM debian:stable-20210902-slim

EXPOSE 698/udp 8081/tcp 53/udp 53/tcp

COPY root/ /
COPY --from=build /usr/local/sbin/ /usr/local/sbin/
COPY --from=build /etc/olsrd/ /etc/olsrd/
RUN chmod 777 /startup.sh /setup/*.sh /named/*.sh && \
    apt update -y && \
    apt install -y libgps-dev vtun bind9 iptables inotify-tools net-tools dnsutils procps iputils-ping traceroute tcpdump && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

ENTRYPOINT ["/startup.sh"]
