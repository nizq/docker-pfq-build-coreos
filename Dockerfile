FROM ubuntu:14.04

RUN echo "===> Installing dev packages..." \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:hvr/ghc \
    && apt-get update \
    && apt-get install -y gcc cmake make bc git cmake g++ flex bison wget strace \
                          gdb python-dev libssl-dev libgeoip-dev cabal-install-1.20 ghc-7.8.4  \
    && echo "export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH" >> ~/.bashrc \
    && export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH \
    && cabal update \
    && export LANG=C.UTF-8 \
    && cabal install alex happy

ENV LANG=C.UTF-8
VOLUME ["/source", "/opt/pfq"]
WORKDIR /source
