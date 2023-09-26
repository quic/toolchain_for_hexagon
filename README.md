# Toolchain for Hexagon

This repository contains scripts and recipes for building a cross toolchain for use with the [Hexagon DSP](https://developer.qualcomm.com/software/hexagon-dsp-sdk/dsp-processor).

Check the releases page for links to binary cross toolchain releases.  These can be used to build and test Hexagon linux userspace binaries, the hexagon linux kernel, and more.

## License
Toolchain for Hexagon is licensed under the BSD 3-clause "New" or "Revised" License. Check out the [LICENSE](LICENSE) for more details.


## Usage

Checkout the required source repos like `llvm-project`, `musl`, etc.  Invoke
`get-src-tarballs.sh` with the corresponding `*_SRC_URL` links to the specific
releases to use (see `Dockerfile` for reference / last-known-good versions).
Or instead you can check out the trunk of those projects' repos using
`git` - try invoking `get_src_repos.sh`.

Once the source repos are setup, build the toolchain using `build-toolchain.sh`.

`build-toolchain.sh` / `build-rootfs.sh` expect the inputs below as environment
variables:

* `ARTIFACT_TAG` - the tag from the llvm-project repo with which this release
should be labeled.
* `TOOLCHAIN_INSTALL` - the path to install the toolchain to.
* `ROOT_INSTALL` - the path to install the rootfs to.  Initially this will
only contain the target includes + libraries.
* `ARTIFACT_BASE` - the path to put the tarballs + manifests.
* optional `MAKE_TARBALLS` - if `MAKE_TARBALLS` is set to `1`, it will create
tarballs of the release and purge the intermediate build artifacts.

Sample usage:

    export ARTIFACT_TAG=17.0.0
    export TOOLCHAIN_INSTALL=$PWD/clang+llvm-${ARTIFACT_TAG}-cross-hexagon-unknown-linux-musl
    export ROOT_INSTALL=$PWD/install_rootfs
    export ARTIFACT_BASE=$PWD/artifacts

    mkdir -p ${ARTIFACT_BASE}

    ./build-toolchain.sh 2>&1 | tee build_${ARTIFACT_TAG}.log
    BUSYBOX_SRC_URL=https://busybox.net/downloads/busybox-1.33.1.tar.bz2 \
       ./build-rootfs.sh 2>&1 | tee build_root.log
