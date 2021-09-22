FROM debian:stable-20210902-slim

RUN apt update ;\
    apt install -y git build-essential bison flex libgps-dev vtun bind9 inotify-tools net-tools dnsutils procps

RUN mkdir build ;\
    cd build ;\
    git clone --depth 1 https://github.com/kn6plv/olsrd.git ;\
    cd olsrd ;\
    make build_all ;\
    make install_all ;\
    cd / ;\
    rm -rf build

RUN apt autoremove -y git build-essential bison flex libgps-dev

EXPOSE 698/udp 8081/tcp 53/udp 53/tcp

COPY root/ /
RUN chmod 777 /startup.sh /setup/*.sh /named/*.sh

ENTRYPOINT ["/startup.sh"]
