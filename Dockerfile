# Build GCC cross compiler
# https://github.com/Lameguy64/PSn00bSDK/blob/master/doc/toolchain.md

FROM debian:bookworm-slim as sdk-build

ARG binutils_version=2.38
ARG gcc_version=12.1.0

RUN apt update && apt install -y wget build-essential

RUN mkdir -p /opt/gcc /opt/gcc/gcc-build /opt/gcc/binutils-build
WORKDIR /opt/gcc

RUN wget https://ftpmirror.gnu.org/gnu/binutils/binutils-${binutils_version}.tar.xz && \
    tar xvf binutils-${binutils_version}.tar.xz && \
    rm -f *.tar.xz
RUN wget https://ftpmirror.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.xz && \
    tar xvf gcc-${gcc_version}.tar.xz && \
    rm -f *.tar.xz

WORKDIR /opt/gcc/gcc-${gcc_version}
RUN ./contrib/download_prerequisites

RUN apt install -y texinfo make cmake

WORKDIR /opt/gcc/binutils-build
RUN ../binutils-${binutils_version}/configure \
    --prefix=/usr/local/mipsel-none-elf --target=mipsel-none-elf \
    --disable-docs --disable-nls --with-float=soft
RUN make -j 4 && make install-strip

WORKDIR /opt/gcc/gcc-build
RUN ../gcc-${gcc_version}/configure \
    --prefix=/usr/local/mipsel-none-elf --target=mipsel-none-elf \
    --disable-docs --disable-nls --disable-libada --disable-libssp \
    --disable-libquadmath --disable-libstdcxx --with-float=soft \
    --enable-languages=c,c++ --with-gnu-as --with-gnu-ld
RUN make -j 4 && make install-strip

ENV PATH=$PATH:/usr/local/mipsel-none-elf/bin

# Build PSn00bSDK

ARG sdk_version=v0.19

RUN mkdir -p /opt/sdk
WORKDIR /opt/sdk
RUN apt install -y git ninja-build
RUN git clone --depth 1 -b ${sdk_version} https://github.com/Lameguy64/PSn00bSDK.git
WORKDIR /opt/sdk/PSn00bSDK
RUN git submodule update --init --recursive --depth 1
# Hack - remove -O2 flag so cmake build type flag works
RUN sed -i 's/-O2/#-O2/' libpsn00b/cmake/flags.cmake
RUN cmake --preset default --install-prefix=/usr/local/libpsn00b -DCMAKE_BUILD_TYPE=MinSizeRel .
RUN cmake --build ./build
RUN cmake --install ./build

# Build clean devshell image

FROM debian:bookworm-slim

COPY --from=sdk-build /usr/local/mipsel-none-elf /usr/local/mipsel-none-elf
COPY --from=sdk-build /usr/local/libpsn00b /usr/local/

RUN apt update && apt install -y cmake ninja-build

ENV PATH=$PATH:/usr/local/mipsel-none-elf/bin
ENV PSN00BSDK_LIBS=/usr/local/lib/libpsn00b

RUN mkdir -p /opt/src
WORKDIR /opt/src
