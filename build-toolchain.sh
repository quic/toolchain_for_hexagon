#!/bin/bash -x

#  Copyright (c) 2021, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

STAMP=${1-$(date +"%Y_%b_%d")}

set -euo pipefail
set -x

build_llvm_clang_cross() {
	triple=${1}
	cd ${BASE}

	EXTRA=""
	if [[ "${triple}" =~ "windows" ]]; then
		EXTRA="-C windows-gnu-target.cmake"
	fi

	CC="zig cc --target=${triple}" \
	ASM="zig cc --target=${triple}" \
	CXX="zig c++ --target=${triple}" \
		cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX:PATH=${TOOLCHAIN_INSTALL}/${triple}/ \
		-DLLVM_CCACHE_BUILD:BOOL=OFF \
		-DLLVM_ENABLE_TERMINFO:BOOL=OFF \
		-DLLVM_ENABLE_ASSERTIONS:BOOL=ON \
		-DLLVM_HOST_TRIPLE=${triple} \
		-DLLVM_TOOL_DSYMUTIL_BUILD:BOOL=OFF \
		-DLLVM_INCLUDE_TESTS:BOOL=OFF \
		-DLLVM_INCLUDE_EXAMPLES:BOOL=OFF \
		-DLLVM_ENABLE_PIC:BOOL=OFF \
		-DLLVM_NATIVE_TOOL_DIR=${PWD}/obj_llvm/bin \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON \
		-DCMAKE_CROSSCOMPILING:BOOL=ON \
		${EXTRA} \
		-C ./hexagon-unknown-linux-musl-clang.cmake \
		-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
		-B ./obj_llvm_${triple} \
		-S ./llvm-project/llvm
	cmake --build ./obj_llvm_${triple} -- -v all install
	DEST_BIN=${TOOLCHAIN_INSTALL}/${triple}/bin
	ln -sf --relative ${DEST_BIN}/llvm-ar ${DEST_BIN}/hexagon-unknown-linux-musl-ar
	ln -sf --relative ${DEST_BIN}/llvm-objdump ${DEST_BIN}/hexagon-unknown-linux-musl-objdump
	ln -sf --relative ${DEST_BIN}/llvm-objcopy ${DEST_BIN}/hexagon-unknown-linux-musl-objcopy
	ln -sf --relative ${DEST_BIN}/llvm-readelf ${DEST_BIN}/hexagon-unknown-linux-musl-readelf
	ln -sf --relative ${DEST_BIN}/llvm-ranlib ${DEST_BIN}/hexagon-unknown-linux-musl-ranlib
}

build_llvm_clang() {
	cd ${BASE}

	CC=clang CXX=clang++ cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX:PATH=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/ \
		-DLLVM_CCACHE_BUILD:BOOL=OFF \
		-DLLVM_ENABLE_LLD:BOOL=ON \
		-DLLVM_ENABLE_LIBCXX:BOOL=ON \
		-DLLVM_ENABLE_TERMINFO:BOOL=OFF \
		-DLLVM_ENABLE_ASSERTIONS:BOOL=ON \
		-DLLVM_ENABLE_PIC:BOOL=OFF \
		-C ./hexagon-unknown-linux-musl-clang.cmake \
		-B ./obj_llvm \
		-S ./llvm-project/llvm
	cmake --build ./obj_llvm -- -v all install
	DEST_BIN=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin
	ln -sf --relative ${DEST_BIN}/llvm-ar ${DEST_BIN}/hexagon-unknown-linux-musl-ar
	ln -sf --relative ${DEST_BIN}/llvm-objdump ${DEST_BIN}/hexagon-unknown-linux-musl-objdump
	ln -sf --relative ${DEST_BIN}/llvm-objcopy ${DEST_BIN}/hexagon-unknown-linux-musl-objcopy
	ln -sf --relative ${DEST_BIN}/llvm-readelf ${DEST_BIN}/hexagon-unknown-linux-musl-readelf
	ln -sf --relative ${DEST_BIN}/llvm-ranlib ${DEST_BIN}/hexagon-unknown-linux-musl-ranlib
}

build_clang_rt_builtins() {
	cd ${BASE}

	PATH=${TOOLCHAIN_BIN}:${PATH} \
		cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_CMAKE_DIR:PATH=${TOOLCHAIN_LIB} \
		-DCOMPILER_RT_EMULATOR:STRING="${TOOLCHAIN_BIN}/qemu_wrapper.sh" \
		-DCMAKE_INSTALL_PREFIX:PATH=${HEX_TOOLS_TARGET_BASE} \
		-DCMAKE_CROSSCOMPILING:BOOL=ON \
		-DCOMPILER_RT_OS_DIR= \
		-DCAN_TARGET_hexagon=1 \
		-DCAN_TARGET_x86_64=0 \
		-DCMAKE_C_COMPILER_FORCED:BOOL=ON \
		-DCMAKE_CXX_COMPILER_FORCED:BOOL=ON \
		-C ./hexagon-linux-builtins.cmake \
		-C ./hexagon-linux-cross.cmake \
		-B ./obj_clang_rt \
		-S ./llvm-project/compiler-rt

	cmake --build ./obj_clang_rt -- -v install
}



config_kernel() {
	cd ${BASE}
	mkdir obj_linux
	cd linux
	make O=../obj_linux ARCH=hexagon \
		CROSS_COMPILE=hexagon-unknown-linux-musl- \
		CC=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/clang \
		AS=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/clang \
		LD=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/ld.lld \
		LLVM=1 \
		LLVM_IAS=1 \
		KBUILD_VERBOSE=1 comet_defconfig
}

build_kernel_headers() {
	cd ${BASE}
	cd linux
	make mrproper
	cd ${BASE}
	cd obj_linux
	make \
	        ARCH=hexagon \
	       	CC=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/clang \
		INSTALL_HDR_PATH=${HEX_TOOLS_TARGET_BASE} \
		V=1 \
		headers_install

}

build_musl_headers() {
	cd ${BASE}
	cd musl
	make clean

	CC=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/hexagon-unknown-linux-musl-clang \
		CROSS_COMPILE=hexagon-unknown-linux-musl \
		LIBCC=${HEX_TOOLS_TARGET_BASE}/lib/libclang_rt.builtins-hexagon.a \
		CROSS_CFLAGS="-G0 -O0 -mv65 -fno-builtin --target=hexagon-unknown-linux-musl" \
		./configure --target=hexagon --prefix=${HEX_TOOLS_TARGET_BASE}
	PATH=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/:$PATH make install-headers

	cd ${HEX_SYSROOT}/..
	ln -sf hexagon-unknown-linux-musl hexagon
}

build_musl() {
	cd ${BASE}
	cd musl
	make clean

	CROSS_COMPILE=hexagon-unknown-linux-musl- \
		AR=llvm-ar \
		RANLIB=llvm-ranlib \
		STRIP=llvm-strip \
		CC=clang \
		LIBCC=${HEX_TOOLS_TARGET_BASE}/lib/libclang_rt.builtins-hexagon.a \
		CFLAGS="${MUSL_CFLAGS}" \
		./configure --target=hexagon --prefix=${HEX_TOOLS_TARGET_BASE}
	PATH=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/:$PATH make -j install
	cd ${HEX_TOOLS_TARGET_BASE}/lib
	ln -sf libc.so ld-musl-hexagon.so
	ln -sf ld-musl-hexagon.so ld-musl-hexagon.so.1
	mkdir -p ${HEX_TOOLS_TARGET_BASE}/../lib
	cd ${HEX_TOOLS_TARGET_BASE}/../lib
	ln -sf ../usr/lib/ld-musl-hexagon.so.1
}


build_libs() {
	cd ${BASE}

	PATH=${TOOLCHAIN_BIN}:${PATH} \
		cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_CMAKE_DIR:PATH=${TOOLCHAIN_LIB} \
		-DCMAKE_INSTALL_PREFIX:PATH=${HEX_TOOLS_TARGET_BASE} \
		-DCMAKE_CROSSCOMPILING:BOOL=ON \
		-DCMAKE_CXX_COMPILER_FORCED:BOOL=ON \
		-C ./hexagon-linux-cross.cmake \
		-C ./hexagon-linux-runtimes.cmake \
		-B ./obj_libs \
		-S ./llvm-project/runtimes

	PATH=${TOOLCHAIN_BIN}:${PATH} \
	cmake --build ./obj_libs -- -v \
		install
}

build_sanitizers() {
	cd ${BASE}
	set -x
	PATH=${TOOLCHAIN_BIN}:${PATH} \
		cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_CMAKE_DIR:PATH=${TOOLCHAIN_LIB} \
		-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX:PATH=${HEX_TOOLS_TARGET_BASE} \
		-DCMAKE_CROSSCOMPILING:BOOL=ON \
		-DCOMPILER_RT_BUILD_BUILTINS:BOOL=OFF \
		-DCOMPILER_RT_BUILD_SANITIZERS:BOOL=ON \
		-DCAN_TARGET_hexagon=1 \
		-DCMAKE_C_COMPILER_FORCED:BOOL=ON \
		-DCMAKE_CXX_COMPILER_FORCED:BOOL=ON \
		-DCOMPILER_RT_SUPPORTED_ARCH=hexagon \
		-DLLVM_TARGET_TRIPLE=hexagon-unknown-linux-musl \
		-C ./hexagon-linux-cross.cmake \
		-B ./obj_san \
		-S ./llvm-project/compiler-rt
	cmake --build ./obj_san -- -v install-compiler-rt
}


build_qemu() {
	cd ${BASE}
	mkdir -p obj_qemu
	cd obj_qemu
	CC=$(which gcc) \
	PATH=${TOOLCHAIN_BIN}:${PATH} \
	../qemu/configure --disable-fdt --disable-capstone --disable-guest-agent \
	                  --disable-containers \
	                  --python=$(which python3.8) \
		--target-list=hexagon-linux-user --prefix=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu \

#	--cc=clang \
#	--cross-prefix=hexagon-unknown-linux-musl-
#	--cross-cc-hexagon="hexagon-unknown-linux-musl-clang" \
#		--cross-cc-cflags-hexagon="-mv67 --sysroot=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/target/hexagon-unknown-linux-musl"

	make -j
	make -j install

	cat <<EOF > ./qemu_wrapper.sh
#!/bin/bash

set -euo pipefail

export QEMU_LD_PREFIX=${HEX_TOOLS_TARGET_BASE}

exec ${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin/qemu-hexagon \$*
EOF
	cp ./qemu_wrapper.sh ${TOOLCHAIN_BIN}/
	chmod +x ./qemu_wrapper.sh ${TOOLCHAIN_BIN}/qemu_wrapper.sh
}

purge_builds() {
	rm -rf ${BASE}/obj_*/
}

set +x

TOOLCHAIN_INSTALL_REL=${TOOLCHAIN_INSTALL}
TOOLCHAIN_INSTALL=$(readlink -f ${TOOLCHAIN_INSTALL})
TOOLCHAIN_BIN=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin
TOOLCHAIN_LIB=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/lib
HEX_SYSROOT=${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/target/hexagon-unknown-linux-musl
HEX_TOOLS_TARGET_BASE=${HEX_SYSROOT}/usr
ROOT_INSTALL_REL=${ROOT_INSTALL}
ROOTFS=$(readlink -f ${ROOT_INSTALL})
RESULTS_DIR_=${ARTIFACT_BASE}/${ARTIFACT_TAG}
mkdir -p ${RESULTS_DIR_}
RESULTS_DIR=$(readlink -f ${RESULTS_DIR_})

if [[ ! -d ${RESULTS_DIR} ]]; then
    echo err results dir "${RESULTS_DIR}" not found or not a dir
    exit 3
fi

REL_NAME=$(basename ${TOOLCHAIN_INSTALL_REL})
BASE=$(readlink -f ${PWD})

if [[ ${MAKE_TARBALLS-0} -eq 1 ]]; then
    echo toolchain will be placed in ${RESULTS_DIR}/${REL_NAME}.tar.xz
    echo creating empty file there as a test:
    echo '' > ${RESULTS_DIR}/${REL_NAME}.tar.xz
fi

ccache --show-stats


MUSL_CFLAGS="-G0 -O0 -mv65 -fno-builtin -mlong-calls --target=hexagon-unknown-linux-musl"

# Workaround, 'C()' macro results in switch over bool:
MUSL_CFLAGS="${MUSL_CFLAGS} -Wno-switch-bool"
# Workaround, this looks like a bug/incomplete feature in the
# hexagon compiler backend:
MUSL_CFLAGS="${MUSL_CFLAGS} -Wno-unsupported-floating-point-opt"

which clang
clang --version
ninja --version
cmake --version
python3.8 --version

build_llvm_clang

CROSS_TRIPLES="aarch64-windows-gnu x86_64-windows-gnu aarch64-linux-gnu aarch64-macos"
CROSS_TRIPLES=""
for t in ${CROSS_TRIPLES}
do
	build_llvm_clang_cross ${t}
done
ccache --show-stats
config_kernel
build_kernel_headers
build_musl_headers
build_clang_rt_builtins
build_musl

build_libs
build_sanitizers


for t in ${CROSS_TRIPLES}
do
	cp -ra ${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/target ${TOOLCHAIN_INSTALL}/${t}
done
build_qemu

cd ${BASE}
if [[ ${MAKE_TARBALLS-0} -eq 1 ]]; then
#   XZ_OPT="-e9T0" tar cJf ${RESULTS_DIR}/${REL_NAME}.tar.xz -C $(dirname ${TOOLCHAIN_INSTALL_REL}) ${REL_NAME}
    tar c -C $(dirname ${TOOLCHAIN_INSTALL_REL}) ${REL_NAME}/x86_64-linux-gnu | xz -e9T0 > ${RESULTS_DIR}/${REL_NAME}.tar.xz
	for t in ${CROSS_TRIPLES}
	do
		if [[ -d ${TOOLCHAIN_INSTALL_REL}/${t} ]]; then
			tar c -C $(dirname ${TOOLCHAIN_INSTALL_REL}) ${REL_NAME}/${t} | xz -e9T0 > ${RESULTS_DIR}/${REL_NAME}_${t}.tar.xz
		fi
	done
    cd ${RESULTS_DIR}
    sha256sum *.tar.xz | tee SHA256SUMS
fi
