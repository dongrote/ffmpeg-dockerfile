FROM ghcr.io/linuxcontainers/debian-slim:latest AS build-ffmpeg
# https://gitlab.com/AOMediaCodec/SVT-AV1/-/commits/master?ref_type=HEADS
ARG SVTAV1_COMMIT_HASH=4f0794415e707daa3ce99791158d033be0196d98
# https://git.ffmpeg.org/gitweb/ffmpeg.git/commit/HEAD
ARG FFMPEG_COMMIT_HASH=9c55f22ef234046dfd47ae414f59e9e2c1530263
# https://github.com/mstorsjo/fdk-aac/commits/master/
ARG FDKAAC_COMMIT_HASH=2ef9a141c40bf254bde7d22c197c615db5b265ed
# https://github.com/Netflix/vmaf/commits/master/
ARG LIBVMAF_COMMIT_HASH=b9ac69e6c4231fad0465021f9e31a841a18261db
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root
RUN apt-get update -qq && apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  doxygen \
  git-core \
  htop \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  libunistring-dev \
  meson \
  nasm \
  ninja-build \
  pkg-config \
  python3 \
  python3-pip \
  python3-dev \
  python3-venv \
  texinfo \
  wget \
  xxd \
  yasm \
  zlib1g-dev
# libx264 (--enable-gpl --enable-libx264)
RUN apt-get -y install libx264-dev
# libx265 (--enable-gpl --enable-libx265)
RUN apt-get -y install libx265-dev libnuma-dev
# libvpx (--enable-libvpx)
RUN apt-get -y install libvpx-dev
# libfdk-aac (--enable-libfdk-aac --enable-nonfree)
#RUN apt-get -y install libfdk-aac-dev
# libopus (--enable-libopus)
RUN apt-get -y install libopus-dev

## build SVT-AV1
# libsvtav1 (--enable-libstvav1)  [encoder only]
## build libsvtav1
## checkout libsvtav1 commit hash $SVTAV1_COMMIT_HASH using sparse checkout
RUN mkdir SVT-AV1 && \
  cd SVT-AV1 && \
  git init && \
  git remote add origin https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
  git fetch origin $SVTAV1_COMMIT_HASH && \
  git checkout FETCH_HEAD
# RUN git clone --depth=1 https://gitlab.com/AOMediaCodec/SVT-AV1.git
RUN cd SVT-AV1/Build && \
  cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
  make -j $(nproc) && make install
# libdav1d (--enable-libdav1d) [decoder only; faster than libaom]
RUN apt-get -y install libdav1d-dev
# libvmaf (--enable-libvmaf)
# -- no deps

## build libfdk-aac
## checkout fdk-aac commit hash $FDKAAC_COMMIT_HASH using sparse checkout
RUN mkdir fdk-aac && \
  cd fdk-aac && \
  git init && \
  git remote add origin https://github.com/mstorsjo/fdk-aac && \
  git fetch origin $FDKAAC_COMMIT_HASH && \
  git checkout FETCH_HEAD

# RUN git clone --depth 1 https://github.com/mstorsjo/fdk-aac
RUN cd fdk-aac && \
    autoreconf -fiv && \
    ./configure && \
    make -j $CPUS && \
    make install

## build libvmaf
## fetch libvmaf source
RUN mkdir vmaf && \
  cd vmaf && \
  git init && \
  git remote add origin https://github.com/Netflix/vmaf && \
  git fetch origin $LIBVMAF_COMMIT_HASH && \
  git checkout FETCH_HEAD
## build
RUN cd vmaf && \
  PATH=/root/vmaf:/root/vmaf/libvmaf/build/tools:$PATH make PYTHON_INTERPRETER=python3 -j$(nproc) && \
  make install

## build ffmpeg
RUN mkdir -p ffmpeg-sources/ffmpeg bin

## checkout ffmpeg commit hash $FFMPEG_COMMIT_HASH using sparse checkout
RUN cd ffmpeg-sources/ffmpeg && \
  git init && \
  git remote add origin https://github.com/FFmpeg/FFmpeg && \
  git fetch origin $FFMPEG_COMMIT_HASH && \
  git checkout FETCH_HEAD
## RUN git clone --depth=1 https://github.com/FFmpeg/FFmpeg ffmpeg-sources/ffmpeg
RUN cd ffmpeg-sources/ffmpeg && \
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:/usr/local/lib/pkgconfig" LD_LIBRARY_PATH="/usr/local/lib" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-gnutls \
# --enable-libaom \
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
  --enable-nonfree && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

FROM ghcr.io/linuxcontainers/debian-slim:latest
WORKDIR /work
COPY --from=build-ffmpeg /root/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=build-ffmpeg /root/bin/ffprobe /usr/bin/ffprobe
COPY --from=build-ffmpeg /usr/local/lib/libSvtAv1Enc.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/fdk-aac/.libs/libfdk-aac.so.2 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /usr/lib/x86_64-linux-gnu /usr/lib/
COPY --from=build-ffmpeg /usr/lib/x86_64-linux-gnu/pulseaudio /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /lib/x86_64-linux-gnu /lib/
COPY --from=build-ffmpeg /usr/local/bin/vmaf /usr/bin/vmaf
COPY --from=build-ffmpeg /usr/local/lib/x86_64-linux-gnu/libvmaf.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/vmaf/model /vmaf/model
ENTRYPOINT ["ffmpeg"]
