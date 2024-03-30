
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
	ca-certificates \
	ccache \
	git \
	software-properties-common \
        bc \
        ninja-build \
	unzip

RUN cat /etc/apt/sources.list | sed "s/^deb\ /deb-src /" >> /etc/apt/sources.list

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
    apt build-dep -yy --arch-only qemu clang python3

# From env.sh
ARG QEMU_REPO QEMU_REF ARTIFACT_BASE ARTIFACT_TAG

ENV VER 17.0.6
ENV TOOLCHAIN_INSTALL /usr/local/clang+llvm-${VER}-cross-hexagon-unknown-linux-musl/
ENV ROOT_INSTALL /usr/local/hexagon-unknown-linux-musl-rootfs
ENV MAKE_TARBALLS 1
#ENV HOST_LLVM_VERSION 10
#ENV CMAKE_VER 3.16.6
#ENV CMAKE_URL https://github.com/Kitware/CMake/releases/download/v3.16.6/cmake-3.16.6-Linux-x86_64.tar.gz

ENV LLVM_SRC_URL https://github.com/llvm/llvm-project/archive/llvmorg-${VER}.tar.gz
ENV MUSL_SRC_URL https://github.com/quic/musl/archive/d125203fcb134febcde6ca32181554560b67c790.tar.gz
ENV LINUX_SRC_URL https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.7.11.tar.xz

#ENV PYTHON_SRC_URL https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tar.xz
#ADD get-host-clang-cmake-python.sh /root/hexagon-toolchain/get-host-clang-cmake-python.sh
#RUN cd /root/hexagon-toolchain && ./get-host-clang-cmake-python.sh

ADD test-suite-patches /root/hexagon-toolchain/test-suite-patches
ADD get-src-tarballs.sh /root/hexagon-toolchain/get-src-tarballs.sh
ADD *.cmake /root/hexagon-toolchain/
RUN cd /root/hexagon-toolchain && ./get-src-tarballs.sh ${PWD} ${TOOLCHAIN_INSTALL}/manifest

ENV IN_CONTAINER 1
ADD build-toolchain.sh /root/hexagon-toolchain/build-toolchain.sh
RUN cd /root/hexagon-toolchain && ./build-toolchain.sh ${ARTIFACT_TAG}

ARG TEST_TOOLCHAIN=1

ENV BUSYBOX_SRC_URL https://busybox.net/downloads/busybox-1.36.1.tar.bz2
ADD build-rootfs.sh /root/hexagon-toolchain/build-rootfs.sh
RUN cd /root/hexagon-toolchain && ./build-rootfs.sh

ADD test-toolchain.sh /root/hexagon-toolchain/test-toolchain.sh
RUN cd /root/hexagon-toolchain && ./test-toolchain.sh
