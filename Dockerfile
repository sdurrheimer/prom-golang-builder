FROM        golang:1.5.3
MAINTAINER  The Prometheus Authors <prometheus-developers@googlegroups.com>

VOLUME  /app
WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
RUN set -x \
    && dpkg --add-architecture arm64 \
    && dpkg --add-architecture armel \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture i386 \
    && dpkg --add-architecture powerpc \
    && dpkg --add-architecture ppc64el \
    && apt-get update && apt-get install -y --force-yes --no-install-recommends \
        libc6-dev-i386 zlib1g-dev libmpc-dev libmpfr-dev libgmp-dev mingw-w64 \
        clang llvm-dev libxml2-dev uuid-dev libssl-dev patch xz-utils bzip2 cpio \
        binutils-multiarch binutils-multiarch-dev gcc-multilib \
    && wget -nv https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 -O /usr/bin/docker \
    && chmod +x /usr/bin/docker \
    && rm -rf /var/lib/apt/lists/*

ENV OSXCROSS_PATH=/usr/osxcross \
    OSXCROSS_REV=8aa9b71a394905e6c5f4b59e2b97b87a004658a4 \
    SDK_VERSION=10.11 \
    DARWIN_VERSION=15 \
    OSX_VERSION_MIN=10.6
RUN set -x \
    && mkdir -p /tmp/osxcross && cd /tmp/osxcross \
    && curl -sL "https://codeload.github.com/tpoechtrager/osxcross/tar.gz/${OSXCROSS_REV}" \
        | tar -C /tmp/osxcross --strip=1 -xzf - \
    && curl -sLo tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz \
        "https://www.dropbox.com/s/bwlbtwywvlu1au7/MacOSX${SDK_VERSION}.sdk.tar.xz" \
    && UNATTENDED=yes ./build.sh \
    && mv target "${OSXCROSS_PATH}" \
    && rm -rf /tmp/osxcross "/usr/osxcross/SDK/MacOSX${SDK_VERSION}.sdk/usr/share/man"

ENV PATH $OSXCROSS_PATH/bin:$PATH

COPY rootfs /

ENTRYPOINT ["/builder.sh"]
