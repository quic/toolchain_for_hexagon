#!/bin/bash

#  Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

get_src_tarballs() {
	cd ${SRC_DIR}
	mkdir -p ${MANIFEST_DIR}

	wget --quiet ${LLVM_SRC_URL} -O llvm-project.tar.xz
	mkdir llvm-project
	cd llvm-project
	tar xf ../llvm-project.tar.xz --strip-components=1
	rm ../llvm-project.tar.xz
	echo ${LLVM_SRC_URL} > ${MANIFEST_DIR}/llvm-project.txt
	cd -

	wget --quiet ${QEMU_SRC_URL} -O qemu.tar.xz
	mkdir qemu
	cd qemu
	tar xf ../qemu.tar.xz --strip-components=1
	rm ../qemu.tar.xz
	echo ${QEMU_SRC_URL} > ${MANIFEST_DIR}/qemu.txt
	cd -

	wget --quiet ${MUSL_SRC_URL} -O musl.tar.xz
	mkdir musl
	cd musl
	tar xf ../musl.tar.xz --strip-components=1
	rm ../musl.tar.xz
	echo ${MUSL_SRC_URL} > ${MANIFEST_DIR}/musl.txt
	cd -

	wget --quiet ${LINUX_SRC_URL} -O linux.tar.xz
	mkdir linux
	cd linux
	tar xf ../linux.tar.xz --strip-components=1
	echo ${LINUX_SRC_URL} > ${MANIFEST_DIR}/linux.txt
	cd -
}

SRC_DIR=${1}
MANIFEST_DIR=${2}
set -x
get_src_tarballs
