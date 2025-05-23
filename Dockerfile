
FROM ubuntu:20.04

ENV HOST_CLANG_VER 12
ENV PATH="/opt/zig-linux-x86_64-0.11.0:$PATH"

# Install common build utilities
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -yy \
	apt-transport-https ca-certificates \
        eatmydata software-properties-common wget gpgv2 unzip && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
        add-apt-repository ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
	wget --quiet https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz && \
	tar xf ./zig-linux-x86_64-0.11.0.tar.xz --directory /opt && \
	wget https://apt.llvm.org/llvm.sh && \
	chmod +x ./llvm.sh && \
	bash -x ./llvm.sh  ${HOST_CLANG_VER} && \
	wget https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip && \
	unzip -d /usr/local/bin ninja-linux.zip && \
	update-alternatives --install /usr/bin/ninja ninja /usr/local/bin/ninja 1 --force && \
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - > /usr/share/keyrings/kitware-archive-keyring.gpg && \
	echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' > /etc/apt/sources.list.d/kitware.list && \
	update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${HOST_CLANG_VER} 100 && \
	update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${HOST_CLANG_VER} 100 && \
    DEBIAN_FRONTEND=noninteractive eatmydata apt update && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
    apt install -y --no-install-recommends \
        bison \
        cmake \
        flex \
        rsync \
        wget \
	build-essential \
	python-is-python3 \
	python3.8 \
	python3.8-venv \
	curl \
	xz-utils \
	zstd \
	ca-certificates \
	ccache \
	git \
	software-properties-common \
        bc \
        ninja-build \
	cpio \
	python3-psutil \
	unzip

RUN cat /etc/apt/sources.list | sed "s/^deb\ /deb-src /" >> /etc/apt/sources.list

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
    apt build-dep -yy --arch-only qemu clang python3

# From env.sh
ARG QEMU_REPO
ARG QEMU_REF=hexagon-sysemu-25-feb-2025

ARG ARTIFACT_BASE
ARG ARTIFACT_TAG

ENV VER 20.1.4
ENV TOOLCHAIN_INSTALL /usr/local/clang+llvm-${VER}-cross-hexagon-unknown-linux-musl/
ENV ROOT_INSTALL /usr/local/hexagon-unknown-linux-musl-rootfs
ENV MAKE_TARBALLS 1

ENV LLVM_SRC_URL https://github.com/llvm/llvm-project/archive/llvmorg-${VER}.tar.gz
ENV ELD_SRC_URL https://github.com/qualcomm/eld/archive/refs/tags/eld_04_16_2025.tar.gz
ENV LLVM_TESTS_SRC_URL https://github.com/llvm/llvm-test-suite/archive/llvmorg-${VER}.tar.gz
ENV MUSL_SRC_URL https://github.com/quic/musl/archive/hexagon-mar1-2025.tar.gz
ENV LINUX_SRC_URL https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.13.5.tar.xz
ENV BUSYBOX_SRC_URL https://busybox.net/downloads/busybox-1.36.1.tar.bz2
ENV BUILDROOT_SRC_URL https://github.com/quic/buildroot/archive/hexagon-2025.04.30.tar.gz

ADD test-suite-patches /root/hexagon-toolchain/test-suite-patches
ADD get-src-tarballs.sh /root/hexagon-toolchain/get-src-tarballs.sh
ADD *.cmake /root/hexagon-toolchain/
RUN cd /root/hexagon-toolchain && ./get-src-tarballs.sh ${PWD} ${TOOLCHAIN_INSTALL}/manifest

ADD test_init/test_init.c test_init/Makefile /root/hexagon-toolchain/test_init/

ENV IN_CONTAINER 1

ENV CROSS_TRIPLES "x86_64-linux-musl aarch64-linux-musl aarch64-windows-gnu x86_64-windows-gnu"
ENV CROSS_TRIPLES_PIC ""
ADD build-toolchain.sh /root/hexagon-toolchain/build-toolchain.sh
RUN cd /root/hexagon-toolchain && ./build-toolchain.sh ${ARTIFACT_TAG}

ADD build-buildroot.sh /root/hexagon-toolchain/build-buildroot.sh
RUN echo 'remoteencoding = UTF-8' >> ~/.wgetrc
RUN cd /root/hexagon-toolchain && ./build-buildroot.sh

ARG TEST_TOOLCHAIN=1

ADD test-toolchain.sh /root/hexagon-toolchain/test-toolchain.sh
RUN cd /root/hexagon-toolchain && ./test-toolchain.sh
