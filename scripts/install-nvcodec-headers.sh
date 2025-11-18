#!/bin/sh

WORKDIR=/root/

set +x
cd $WORKDIR
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd $WORKDIR/nv-codec-headers
make install
