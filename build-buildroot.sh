#!/bin/bash

#  Copyright (c) 2024, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

BASE=$(readlink -f ${PWD})

set -x
TOOLCHAIN_INSTALL_REL=${TOOLCHAIN_INSTALL}
TOOLCHAIN_INSTALL=$(readlink -f ${TOOLCHAIN_INSTALL})
TOOLCHAIN_BIN=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin
export PATH=${TOOLCHAIN_BIN}:${PATH}

# TODO: change build to use unprivileged user
export FORCE_UNSAFE_CONFIGURE=1

make -C buildroot/ O=${PWD}/obj_buildroot/ qcom_dsp_qemu_defconfig
make -C obj_buildroot -j
make -C obj_buildroot legal-info
install -D ./obj_buildroot/images/* ${ARTIFACT_BASE}/${ARTIFACT_TAG}/
