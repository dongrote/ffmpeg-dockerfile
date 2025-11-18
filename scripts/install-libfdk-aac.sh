#!/bin/sh

WORKDIR=/root/fdk-aac

set +x

mkdir $WORKDIR && \
  cd $WORKDIR && \
  git init && \
  git remote add origin https://github.com/mstorsjo/fdk-aac && \
  git fetch origin $FDKAAC_COMMIT_HASH && \
  git checkout FETCH_HEAD

autoreconf -fiv && \
    ./configure && \
    make -j $CPUS && \
    make install
