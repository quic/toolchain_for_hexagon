cmake_minimum_required(VERSION 3.22)
project(
  "Hexagon open source toolchain"
  DESCRIPTION "It is a sample toolchain to support Hexagon"
  HOMEPAGE_URL "https://github.com/quic/toolchain_for_hexagon"
  LANGUAGES NONE)


# Set variables with CACHE option to allow command line override
set(HOST_CLANG_VER 20 CACHE STRING "Host Clang version")
set(ARTIFACT_TAG 20.0.0 CACHE STRING "Artifact tag")
set(INSTALL_ROOT /tmp/$ENV{USER}/hexagon-qemu CACHE STRING "Install root")
set(TOOLCHAIN_INSTALL ${INSTALL_ROOT}/clang+llvm-${ARTIFACT_TAG}-cross-hexagon-unknown-linux-musl)
set(ROOT_INSTALL ${INSTALL_ROOT}/install_rootfs)
set(ARTIFACT_BASE ${INSTALL_ROOT}/artifacts)

set(TOOLCHAIN_INSTALL_REL ${TOOLCHAIN_INSTALL})
set(TOOLCHAIN_BIN ${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/bin)
set(TOOLCHAIN_LIB ${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/lib)
set(HEX_SYSROOT ${TOOLCHAIN_INSTALL}/x86_64-linux-gnu/target/hexagon-unknown-linux-musl)
set(HEX_TOOLS_TARGET_BASE ${HEX_SYSROOT}/usr)
set(ROOT_INSTALL_REL ${ROOT_INSTALL})
set(ROOTFS ${ROOT_INSTALL})
set(RESULTS_DIR ${ARTIFACT_BASE}/${ARTIFACT_TAG})

# Custom commands
add_custom_target(setup
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ARTIFACT_BASE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${RESULTS_DIR}
    COMMAND ${CMAKE_COMMAND} -E echo_append ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND ${CMAKE_COMMAND} -E echo_append ${TOOLCHAIN_INSTALL_REL}
)

add_custom_target(clone
    DEPENDS setup
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/get-src-repos.sh ${CMAKE_CURRENT_SOURCE_DIR} ${TOOLCHAIN_INSTALL_REL}
)

add_custom_target(eld
    DEPENDS clone
    COMMAND ${CMAKE_COMMAND} -E chdir llvm-project git clone git@github.qualcomm.com:cgit/eld.git
)

#
# NOTE:
#   DEPENDS eld
# Remove this when incrementally building
# the scripts are very picky about running more than once.
#
add_custom_target(tools
    DEPENDS eld
    COMMAND
    env TOOLCHAIN_INSTALL=${TOOLCHAIN_INSTALL}
    env ROOT_INSTALL=${ROOT_INSTALL}
    env ARTIFACT_BASE=${ARTIFACT_BASE}
    env ARTIFACT_TAG=${ARTIFACT_TAG}
    env CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/build-toolchain.sh
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
