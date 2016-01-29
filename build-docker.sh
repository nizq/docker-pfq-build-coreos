#!/bin/sh

# docker run --name ghc-cross nilcons/ghc-cross
# docker cp ghc-cross:/ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz .
# docker rm ghc-cross

# stole ghc-musl from https://github.com/nilcons/ghc-musl, thanks!
docker build -t nizq/alpine-ghc-build .

git clone https://github.com/coreos/linux.git
git clone https://github.com/pfq/PFQ.git

docker run -it --rm -v `pwd`:/source nizq/alpine-build /source/build-pfq.sh

cp Dockerfile.final final/Dockerfile
cd final
docker build -t nizq/pfq .
