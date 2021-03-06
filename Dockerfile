FROM ubuntu:14.04

RUN echo "===> Installing dev packages..." \
    && HEADER_VERSION=4.2.0-25 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:hvr/ghc \
    && apt-get update \
    && apt-get install -y gcc cmake make bc git cmake g++ flex bison wget strace \
                          linux-headers-${HEADER_VERSION}-generic vim \
                          gdb python-dev libssl-dev libgeoip-dev cabal-install-1.20 ghc-7.8.4

ENV LANG=C.UTF-8
VOLUME ["/source", "/usr/local" "/root/.ghc", "/root/.cabal"]
WORKDIR /source
