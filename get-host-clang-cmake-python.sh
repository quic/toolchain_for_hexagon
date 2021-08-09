#!/bin/bash

# must run as superuser
set -euo pipefail

set -x

# cmake
cd /tmp ; wget --quiet ${CMAKE_URL}
cd /opt ; tar xf /tmp/$(basename ${CMAKE_URL})
ln -sf cmake-${CMAKE_VER}-Linux-x86_64 cmake-latest
cd -
sh -c 'echo "export PATH=/opt/cmake-latest/bin:\${PATH}" > /etc/profile.d/cmake-latest.sh'

# ninja
cd /opt 
mkdir ninja-latest 
cd ninja-latest

wget --quiet https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip
unzip ninja-linux.zip 
sh -c 'echo "export PATH=/opt/ninja-latest:\${PATH}" > /etc/profile.d/ninja-latest.sh'
rm ninja-linux.zip 
