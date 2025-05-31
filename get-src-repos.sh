#!/bin/bash

#  Copyright (c) 2021, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

SRC_DIR=${1}
MANIFEST_DIR=${2}

git clone -q https://github.com/llvm/llvm-project &
git clone -q https://github.com/llvm/llvm-test-suite &
git clone --depth=1 -q git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux &
git clone --depth=1 -q https://github.com/python/cpython &
git clone --depth=1 -q git://repo.or.cz/libc-test &
git clone -q https://git.busybox.net/busybox/ &
git clone -q https://github.com/quic/buildroot/ &


git clone -q --branch=hexagon https://github.com/quic/musl &
git clone -q https://github.com/quic/hexagonMVM &
git clone -q https://github.com/qemu/qemu &

wait
git clone -q https://github.com/qualcomm/eld/ llvm-project/eld/

dump_checkout_info() {
	out=${1}
	mkdir -p ${out}
	for d in ./*
	do
		if [[ -d ${d} ]]; then
			proj=$(basename ${d})
			cd ${d}
			git remote -v > ${out}/${proj}.txt
			git log -3 HEAD >> ${out}/${proj}.txt
			cd -
		fi
	done
}

mkdir -p ${MANIFEST_DIR}
dump_checkout_info ${MANIFEST_DIR}

cat <<EOF
Now that you've cloned the source repos, refer to Dockerfile to find the git refs
of each repo that should be checked out to build a known good configuration.
EOF
