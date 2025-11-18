#!/bin/sh

WORKDIR=/root/ffmpeg-sources/ffmpeg

set +x

# deps from https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html
apt-get install -y \
  build-essential \
  yasm \
  cmake \
  libtool \
  libc6 \
  libc6-dev \
  unzip \
  wget \
  libnuma1 \
  libnuma-dev

mkdir -p $WORKDIR bin

## checkout ffmpeg commit hash $FFMPEG_COMMIT_HASH using sparse checkout
cd $WORKDIR && \
  git init && \
  git remote add origin https://github.com/FFmpeg/FFmpeg && \
  git fetch origin $FFMPEG_COMMIT_HASH && \
  git checkout FETCH_HEAD

export PATH="$HOME/bin:$PATH:/usr/local/cuda/bin"
export PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:/usr/local/lib/pkgconfig"
export LD_LIBRARY_PATH="/usr/local/lib"
./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include -I/usr/local/cuda/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib -L/usr/local/cuda/lib64" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --enable-nonfree \
  --enable-cuda-nvcc \
  --enable-gpl \
  --enable-gnutls \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsvtav1 \
  --enable-libdav1d \
  --enable-libvmaf \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-shared \
  --disable-static
export PATH="$HOME/bin:$PATH"
make -j$(nproc) && make install