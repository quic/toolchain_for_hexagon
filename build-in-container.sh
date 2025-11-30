#!/bin/sh

#  Copyright (c) 2024, Qualcomm Innovation Center, Inc. All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause

set -e

if test -z "$ARTIFACT_TAG"
then
    echo "Please set ARTIFACT_TAG env var"
    exit 1
fi

DOCKER_BUILD_ARGS="
--build-arg ARTIFACT_BASE=/usr/local/hexagon-artifacts
--build-arg QEMU_REPO=https://github.com/quic/qemu
--build-arg QEMU_REF=hexagon-sysemu-29-nov-2025
--build-arg ARTIFACT_TAG=${ARTIFACT_TAG}"

#build
docker build ${DOCKER_BUILD_ARGS} -t hexagon:latest -f ./Dockerfile .
docker build ${DOCKER_BUILD_ARGS} -t hexagon-win:latest -f ./cross-win/Dockerfile .

#debug
docker images

#extract artifacts
for name in hexagon hexagon-win; do
    docker rm -f tmp_container || /bin/true
    docker create --name tmp_container $name:latest
    docker cp tmp_container:/usr/local/hexagon-artifacts ./hexagon-artifacts
    docker rm tmp_container
done
