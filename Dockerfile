FROM debian:bullseye-slim AS build
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root
RUN apt-get update -qq && apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
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
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev
# NASM
RUN apt-get -y install nasm
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
# libsvtav1 (--enable-libstvav1)  [encoder only]
RUN git clone --depth=1 https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
  cd SVT-AV1/Build && \
  cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
  make -j $(nproc) && make install
# libdav1d (--enable-libdav1d) [decoder only; faster than libaom]
RUN apt-get -y install libdav1d-dev
# libvmaf (--enable-libvmaf)
# -- no deps
RUN mkdir -p ffmpeg-sources bin
RUN cd ffmpeg-sources && \
  wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
  tar xjvf ffmpeg-snapshot.tar.bz2
RUN cd ffmpeg-sources/ffmpeg && \
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
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
# --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsvtav1 \
  --enable-libdav1d \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

FROM debian:bullseye-slim AS publish
COPY --from=build /root/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=build /usr/local/lib/libSvtAv1Enc.so.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build /usr/lib/x86_64-linux-gnu /usr/lib/
COPY --from=build /usr/lib/x86_64-linux-gnu/pulseaudio /usr/lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu /lib/
