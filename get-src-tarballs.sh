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

	wget --quiet ${ELD_SRC_URL} -O eld.tar.xz
	mkdir llvm-project/eld
	cd llvm-project/eld
	tar xf ../../eld.tar.xz --strip-components=1
	rm ../../eld.tar.xz
	echo ${ELD_SRC_URL} > ${MANIFEST_DIR}/eld.txt
	cd -

	wget --quiet ${LLVM_TESTS_SRC_URL} -O llvm-test-suite.tar.xz
	mkdir llvm-test-suite
	cd llvm-test-suite
	tar xf ../llvm-test-suite.tar.xz --strip-components=1
	rm ../llvm-test-suite.tar.xz
	echo ${LLVM_TESTS_SRC_URL} > ${MANIFEST_DIR}/llvm-test-suite.txt
	cd -

	git clone --branch ${QEMU_REF} ${QEMU_REPO}
	cd qemu
	git remote -v > ${MANIFEST_DIR}/qemu.txt
	git log -3 HEAD >> ${MANIFEST_DIR}/qemu.txt
	cd -

	wget --quiet ${MUSL_SRC_URL} -O musl.tar.xz
	mkdir musl
	cd musl
	tar xf ../musl.tar.xz --strip-components=1
	rm ../musl.tar.xz
	echo ${MUSL_SRC_URL} > ${MANIFEST_DIR}/musl.txt
	cd -

	wget --quiet ${BUILDROOT_SRC_URL} -O buildroot.tar.xz
	mkdir buildroot
	cd buildroot
	tar xf ../buildroot.tar.xz --strip-components=1
	echo ${BUILDROOT_SRC_URL} > ${MANIFEST_DIR}/buildroot.txt
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
