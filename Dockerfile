
FROM debian:stretch

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y keepalived ipset curl procps net-tools && \
    rm -rf /var/lib/apt/lists/*

COPY ./build/keepalived/keepalived  /etc/keepalived/
COPY ./build/keepalived/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

