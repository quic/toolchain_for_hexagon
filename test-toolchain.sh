#!/bin/bash

#  Copyright (c) 2021, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

STAMP=${1-$(date +"%Y_%b_%d")}
LLVM_TS_PER_TEST_TIMEOUT_SEC=$((10 * 60))

# For now let's limit the scope of this test suite
LLVM_TS_LIMIT=400

if [ -z "${CURRENT_SOURCE_DIR}" ]; then
  CURRENT_SOURCE_DIR=${PWD}
fi

set -euo pipefail

test_llvm() {
	OPT_CMAKE=${1}
	if [[ ${OPT_CMAKE} == '' ]]; then
		OPT_FLAVOR='default'
		OPT_CMAKE_CMDLINE=""
	else
		OPT_FLAVOR=$(basename -- "${OPT_CMAKE}" .cmake)
		OPT_CMAKE_CMDLINE="-C ${OPT_CMAKE}"
	fi
	cd ${BASE}

	PATH=${TOOLCHAIN_BIN}:${PATH} \
		cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		${OPT_CMAKE_CMDLINE} \
		-DTEST_SUITE_CXX_ABI:STRING=libc++abi \
		-DTEST_SUITE_RUN_UNDER:STRING="${TOOLCHAIN_BIN}/qemu_wrapper.sh" \
		-DTEST_SUITE_USER_MODE_EMULATION:BOOL=ON \
		-DTEST_SUITE_RUN_BENCHMARKS:BOOL=ON \
		-DTEST_SUITE_LIT:FILEPATH="${BASE}/obj_llvm/bin/llvm-lit" \
		-DBENCHMARK_USE_LIBCXX:BOOL=ON \
		-DSMALL_PROBLEM_SIZE:BOOL=ON \
		-C ${CURRENT_SOURCE_DIR}/hexagon-linux-cross.cmake \
		-B ./obj_test-suite_${OPT_FLAVOR} \
		-S ./llvm-test-suite

	cmake --build ./obj_test-suite_${OPT_FLAVOR} -- -v -k 0
#	cmake --build ./obj_test-suite_${OPT_FLAVOR} -- -v check
	cd ./obj_test-suite_${OPT_FLAVOR}
	python3 ${BASE}/obj_llvm/bin/llvm-lit -v \
		--show-all \
		--show-pass \
		--show-skipped \
		--time-tests \
		--max-tests=${LLVM_TS_LIMIT} \
		--timeout=${LLVM_TS_PER_TEST_TIMEOUT_SEC} \
		-o ${RESULTS_DIR}/test_res_${OPT_FLAVOR}.json \
		MultiSource/Benchmarks/{mediabench,VersaBench,Trimaran,BitBench,Rodinia,Fhourstones*,FreeBench} \
		SingleSource/Benchmarks/{Linpack,Dhrystone,BenchmarkGame,Stanford} \
		SingleSource/Regression/C \
		SingleSource/UnitTests/Vector \
		External/SPEC \
		Bitcode/Regression
	llvm_result=${?}
}

test_qemu() {
	cd ${BASE}
	cd obj_qemu

	make check V=1 --keep-going
	PATH=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin:$PATH \
		QEMU_LD_PREFIX=${HEX_TOOLS_TARGET_BASE} \
		make check-tcg TIMEOUT=180 CROSS_CC_GUEST=hexagon-unknown-linux-musl-clang V=1 --keep-going
	qemu_result=${?}
}

test_libc() {
	cd ${BASE}
	mkdir obj_test-libc
	cd obj_test-libc

	rm -f ../libc-test/config.mak
	cat ../libc-test/config.mak.def - <<EOF >> ../libc-test/config.mak
CFLAGS+=${MUSL_CFLAGS}
EOF

	PATH=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/:$PATH \
		CC=${TOOLCHAIN_BIN}/hexagon-unknown-linux-musl-clang \
		QEMU_LD_PREFIX=${HEX_TOOLS_TARGET_BASE} \
		make V=1 \
		--directory=../libc-test \
		B=${PWD} \
		CROSS_COMPILE=hexagon-unknown-linux-musl- \
		AR=llvm-ar \
		RANLIB=llvm-ranlib \
		RUN_WRAP=${TOOLCHAIN_BIN}/qemu_wrapper.sh
	libc_result=${?}
	cp ./REPORT ${RESULTS_DIR}/libc_test_REPORT
	head ./REPORT $(find ${PWD} -name '*.err' | sort) > ${RESULTS_DIR}/libc_test_failures_err.log
}

TOOLCHAIN_INSTALL_REL=${TOOLCHAIN_INSTALL}
TOOLCHAIN_INSTALL=$(readlink -f ${TOOLCHAIN_INSTALL})
TOOLCHAIN_BIN=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin
HEX_SYSROOT=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/target/hexagon-unknown-linux-musl
HEX_TOOLS_TARGET_BASE=${HEX_SYSROOT}/usr
ROOT_INSTALL_REL=${ROOT_INSTALL}
#ROOTFS=$(readlink -f ${ROOT_INSTALL})
RESULTS_DIR=$(readlink -f ${ARTIFACT_BASE}/${ARTIFACT_TAG})


BASE=$(readlink -f ${PWD})

MUSL_CFLAGS="-G0 -O2 -mv65 -fno-builtin  --target=hexagon-unknown-linux-musl"

# Workaround, 'C()' macro results in switch over bool:
MUSL_CFLAGS="${MUSL_CFLAGS} -Wno-switch-bool"
# Workaround, this looks like a bug/incomplete feature in the
# hexagon compiler backend:
MUSL_CFLAGS="${MUSL_CFLAGS} -Wno-unsupported-floating-point-opt"

llvm_result=0
libc_result=0
qemu_result=0

set -x

if [[ ${TEST_TOOLCHAIN-0} -eq 1 ]]; then
	# needs google benchmark changes to count hexagon cycles
	# in order to build, see ./test-suite-patches
	set +e
	for opt in target-hexagon-v79-O2 O0 CodeSize MinSize O2
	do
		cmake=$(readlink -f llvm-test-suite/cmake/caches/${opt}.cmake)
		test_llvm ${cmake} 2>&1 | tee ${RESULTS_DIR}/llvm-test-suite_${opt}.log
	done
	test_llvm '' 2>&1 | tee ${RESULTS_DIR}/llvm-test-suite_default.log

	test_libc 2>&1 | tee ${RESULTS_DIR}/libc_test_detail.log
	test_qemu 2>&1 | tee ${RESULTS_DIR}/qemu_test_check-tcg.log
	set -e
fi

echo done
echo llvm: ${llvm_result}
echo libc: ${libc_result}
echo qemu: ${qemu_result}
exit $(( ${libc_result} + ${qemu_result} + ${llvm_result} ))
