# Local experimentation

Sometimes it's more convenient to run a build / test of a toolchain
locally.  Here's how to do it.  Note that you will need to satisfy the
several build dependencies yourself in order to use this option.  Consult
the `Dockerfile` for a reference on the dependencies.

# Workspace setup

You must clone all of the source repos:

    ./get-src-repos.sh ${PWD} ${PWD}/install/manifest

You must apply a local patch to the llvm-test-suite for Hexagon:

    cd llvm-test-suite
    git am ../test-suite-patches/0001-Add-cycle-read-for-hexagon.patch

## Building the toolchain

To build (outside of docker) you can run `build-toolchain.sh`.  Note that
you must define the expected input environment variables.  For example:

    TOOLCHAIN_INSTALL=${PWD}/install \
    ROOT_INSTALL=${PWD}/rootfs \
    ARTIFACT_BASE=${PWD}/artifacts \
    ARTIFACT_TAG=main \
        ./build-toolchain.sh

The example above will build the toolchain and install it to `./install`.

## Testing the toolchain

To test the toolchain locally you can run `test-toolchain.sh`.  Also in
this case define the expected input environment variables.  For example:

    TEST_TOOLCHAIN=1 \
    TOOLCHAIN_INSTALL=${PWD}/install \
    ROOT_INSTALL=${PWD}/rootfs \
    ARTIFACT_BASE=${PWD}/artifacts \
    ARTIFACT_TAG=main \
        ./test-toolchain.sh

This will launch the test suites and store the test results
under `./artifacts/main`.
