FROM ubuntu:24.04

RUN cp /etc/apt/sources.list /etc/apt/sources.list~ && \
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt install -y make build-essential \
        wget flex bison unzip python-is-python3 python3-pip \
        ninja-build pkg-config libpixman-1-dev libglib2.0-dev git wget \
        curl libelf-dev libvirglrenderer-dev libepoxy-dev libgtk-3-dev \
        libgcrypt20-dev libgpg-error-dev libzip-dev bash coreutils \
        git git-lfs libncurses6 mingw-w64 msitools libz-mingw-w64-dev \
        pkg-config-mingw-w64-x86-64 zstd cmake wine && \
    DEBIAN_FRONTEND=noninteractive apt build-dep -yy qemu

# Windows libs
RUN for url in https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-glib2-2.84.1-2-any.pkg.tar.zst \
               https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-pixman-0.44.2-1-any.pkg.tar.zst \
               https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-libpng-1.6.47-1-any.pkg.tar.zst \
               https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gettext-0.22.4-3-any.pkg.tar.zst \
               https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-pcre2-10.45-1-any.pkg.tar.zst \
               https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-libiconv-1.18-1-any.pkg.tar.zst; do \
        wget $url && tar xvf $(basename $url) --no-same-permissions --no-same-owner || exit 2; \
    done && \
    rm -rf *.tar.zst .[A-Za-z]*

# Other configs
RUN update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
ENV PKG_CONFIG_PATH "/mingw64/lib/pkgconfig"
ENV WINEPATH "/mingw64/bin;/usr/x86_64-w64-mingw32/lib/;/usr/lib/gcc/x86_64-w64-mingw32/12-posix/"
# This may fail due to missing display, but it actually sets the
# configs we need before doing so.
RUN winecfg || true
# For some reason `winecfg` only creates this file when run in the container,
# not during image creation. So we save and copy them over.
COPY cross-win/wine/* /root/.wine/

# From env.sh
ARG QEMU_REPO
ARG QEMU_REF
ARG ARTIFACT_BASE
ARG ARTIFACT_TAG

ARG QEMU_INSTALL_DIR=qemu-hexagon-x86_64-win
ARG QEMU_CLONE_DIR=/root/qemu

RUN git clone --branch ${QEMU_REF} ${QEMU_REPO} ${QEMU_CLONE_DIR} && \
    mkdir -p ${QEMU_CLONE_DIR}/build && cd ${QEMU_CLONE_DIR}/build && \
    CC=$(which gcc) && \
    ../configure --without-default-features --disable-fdt --disable-capstone \
                 --disable-guest-agent --disable-containers \
                 --enable-slirp \
                 --enable-fdt \
                 --enable-plugins \
                 --cross-prefix=x86_64-w64-mingw32- \
                 --target-list=hexagon-softmmu \
                 --prefix=${QEMU_CLONE_DIR}/build/${QEMU_INSTALL_DIR} && \
    make -j && make -j install && \
    RESULTS_DIR=${ARTIFACT_BASE}/${ARTIFACT_TAG} && mkdir -p ${RESULTS_DIR} && \
    tar c ${QEMU_INSTALL_DIR} | xz -e9T0 > ${RESULTS_DIR}/${QEMU_INSTALL_DIR}.tar.xz && \
    cd ${RESULTS_DIR} && \
    sha256sum ${QEMU_INSTALL_DIR}.tar.xz > ${QEMU_INSTALL_DIR}.tar.xz.sha256
