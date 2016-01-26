#!/bin/sh

docker run --name ghc-cross nilcons/ghc-cross
docker cp ghc-cross:/ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz .
docker rm ghc-cross

# stole ghc-musl from https://github.com/nilcons/ghc-musl, thanks!
docker build -t nizq/alpine-ghc-build .

# docker run -it --name alpine-build -v `pwd`/linux:/src/linux-`uname -r`  -v /lib/modules/`uname -r`:/lib/modules/`uname -r` -v /usr/local:/usr/local -v `pwd`:/source nizq/alpine-build build-pfq.sh

git clone https://github.com/coreos/linux.git
git clone https://github.com/pfq/PFQ.git
