
FROM ubuntu:16.04

ENV HOST_CLANG_VER 12

# Install common build utilities
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -yy \
	apt-transport-https ca-certificates \
        eatmydata software-properties-common wget gpgv2 unzip && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
        add-apt-repository ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive eatmydata \
	wget https://apt.llvm.org/llvm.sh && \
	chmod +x ./llvm.sh && \
	bash -x ./llvm.sh  ${HOST_CLANG_VER} && \
	wget https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip && \
	unzip -d /usr/local/bin ninja-linux.zip && \
	update-alternatives --install /usr/bin/ninja ninja /usr/local/bin/ninja 1 --force && \
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - > /usr/share/keyrings/kitware-archive-keyring.gpg && \
	echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ xenial main' > /etc/apt/sources.list.d/kitware.list && \
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
	python3.6 \
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
    apt build-dep -yy --arch-only qemu clang python

ENV TOOLCHAIN_INSTALL /usr/local/clang+llvm-Aug-2021-cross-hexagon-unknown-linux-musl/
ENV ROOT_INSTALL /usr/local/hexagon-unknown-linux-musl-rootfs
ENV ARTIFACT_BASE /usr/local/hexagon-artifacts
ENV MAKE_TARBALLS 1
#ENV HOST_LLVM_VERSION 10
#ENV CMAKE_VER 3.16.6
#ENV CMAKE_URL https://github.com/Kitware/CMake/releases/download/v3.16.6/cmake-3.16.6-Linux-x86_64.tar.gz

# 630818a850f754af852247c775280de6fde8560e ~April 2021, after cs0/cs1 update
# cc38f8939da4aec85e7d0ef4de412e30d4de5a14 ~July 2021, after hexagon_types.h update
# 68ab571e22e7dadf1262bba415e1365105d07a65 ~Aug 2021, after sanitizer update
ENV LLVM_SRC_URL https://github.com/llvm/llvm-project/archive/68ab571e22e7dadf1262bba415e1365105d07a65.tar.gz
# 15106f7dc3290ff3254611f265849a314a93eb0e qemu/qemu 2 May 2021, hexagon scalar core support
# 628eea52b33dae2ea2112c85c2c95e9f8832b846 quic/qemu 23 Apr 2021, latest hexagon core + HVX support
# 0a0f70dd3bec32212e7996feb8371788bc00d183 quic/qemu 3 Jul 2021, bugfixes
ARG QEMU_REPO=https://github.com/quic/qemu
ARG QEMU_SHA=0a0f70dd3bec32212e7996feb8371788bc00d183

ENV MUSL_SRC_URL https://github.com/quic/musl/archive/7243e0d3a9d7e0f08d21fc194a05749e0bb26725.tar.gz
ENV LINUX_SRC_URL https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.13.tar.xz

#ENV PYTHON_SRC_URL https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tar.xz
#ADD get-host-clang-cmake-python.sh /root/hexagon-toolchain/get-host-clang-cmake-python.sh
#RUN cd /root/hexagon-toolchain && ./get-host-clang-cmake-python.sh

ADD get-src-tarballs.sh /root/hexagon-toolchain/get-src-tarballs.sh
RUN cd /root/hexagon-toolchain && ./get-src-tarballs.sh ${PWD} ${TOOLCHAIN_INSTALL}/manifest

ARG ARTIFACT_TAG=untagged
ADD build-toolchain.sh /root/hexagon-toolchain/build-toolchain.sh
RUN cd /root/hexagon-toolchain && ./build-toolchain.sh Aug-2021

ARG TEST_TOOLCHAIN=1

ENV BUSYBOX_SRC_URL https://busybox.net/downloads/busybox-1.33.1.tar.bz2
ADD build-rootfs.sh /root/hexagon-toolchain/build-rootfs.sh
RUN cd /root/hexagon-toolchain && ./build-rootfs.sh

ADD test-toolchain.sh /root/hexagon-toolchain/test-toolchain.sh
RUN cd /root/hexagon-toolchain && ./test-toolchain.sh
