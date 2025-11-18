#!/bin/sh

WORKDIR=/root/vmaf

set +x

## fetch libvmaf source
mkdir $WORKDIR && \
  cd $WORKDIR && \
  git init && \
  git remote add origin https://github.com/Netflix/vmaf && \
  git fetch origin $LIBVMAF_COMMIT_HASH && \
  git checkout FETCH_HEAD
## build
export PATH=$WORKDIR:$WORKDIR/libvmaf/build/tools:$PATH:/usr/local/cuda/bin
make PYTHON_INTERPRETER=python3 -j$(nproc) && \
  make install