#!/bin/sh

WORKDIR=/root/

set +x

cd $WORKDIR
apt-get install -y software-properties-common
add-apt-repository -y contrib
. /etc/os-release
wget https://developer.download.nvidia.com/compute/cuda/repos/${ID}${VERSION_ID}/$(uname -m)/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update
apt-get install -y cuda-toolkit

# we also need more nvidia libraries
# libnvidia-encode.so.1
# libnvcuvid.so.1
apt-get install -y libnvidia-encode1