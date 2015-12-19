FROM        golang:1.5.2
MAINTAINER  The Prometheus Authors <prometheus-developers@googlegroups.com>

VOLUME  /app
WORKDIR /app

RUN \
    wget -nv https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 -O /usr/bin/docker \
    && chmod +x /usr/bin/docker

COPY rootfs /

ENTRYPOINT ["/builder.sh"]
