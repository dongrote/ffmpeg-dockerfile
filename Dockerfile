FROM ghcr.io/linuxcontainers/debian-slim:latest AS build-ffmpeg
# https://gitlab.com/AOMediaCodec/SVT-AV1/-/commits/master?ref_type=HEADS
ARG SVTAV1_COMMIT_HASH=090bdfbaa7a3628af218a41275662c55f0f3b937
ENV SVTAV1_COMMIT_HASH=${SVTAV1_COMMIT_HASH}
# https://git.ffmpeg.org/gitweb/ffmpeg.git/commit/HEAD
ARG FFMPEG_COMMIT_HASH=643e2e10f980cf99c4e37da027b209dcdc1ac56f
ENV FFMPEG_COMMIT_HASH=${FFMPEG_COMMIT_HASH}
# https://github.com/mstorsjo/fdk-aac/commits/master/
ARG FDKAAC_COMMIT_HASH=d8e6b1a3aa606c450241632b64b703f21ea31ce3
ENV FDKAAC_COMMIT_HASH=${FDKAAC_COMMIT_HASH}
# https://github.com/Netflix/vmaf/commits/master/
ARG LIBVMAF_COMMIT_HASH=e0d9b82d3b55de55927f1e7e7bd11f40a35de3e0
ENV LIBVMAF_COMMIT_HASH=${LIBVMAF_COMMIT_HASH}
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root
COPY scripts/ /root/scripts/
RUN apt-get update -qq && apt-get upgrade -y && apt-get -y install \
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

## build and install libfdk-aac
RUN /root/scripts/install-libfdk-aac.sh

# Install nv-codec-headers for libvmaf and ffmpeg NVENC/NVDEC support
RUN /root/scripts/install-nvcodec-headers.sh
RUN /root/scripts/install-nvidia-cuda-toolkit.sh

## build libvmaf; latest libvmaf requires nv-codec-headers
RUN /root/scripts/install-libvmaf.sh

## build ffmpeg
RUN /root/scripts/install-ffmpeg.sh

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
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libavdevice.so.62 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libavcodec.so.62 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libavformat.so.62 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libavfilter.so.11 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libavutil.so.60 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libswresample.so.6 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /root/ffmpeg_build/lib/libswscale.so.9 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /usr/lib/x86_64-linux-gnu/libnvcuvid.so.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build-ffmpeg /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.1 /usr/lib/x86_64-linux-gnu/
ENTRYPOINT ["ffmpeg"]
