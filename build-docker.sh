#!/bin/bash

docker build -t nizq/ubuntu-pfq-build .
mkdir -p final/dist final/ghc final/cabal
docker run -it --rm -v `pwd`:/source \
       -v `pwd`/final/dist:/usr/local \
       -v `pwd`/final/ghc:/root/.ghc \
       -v `pwd`/final/cabal:/root/.cabal \
       nizq/ubuntu-pfq-build /source/build-pfq.sh admin

cp Dockerfile.admin final/Dockerfile
cd final
sudo docker build -t nizq/pfq-admin .

cd ..
docker run -it --rm -v `pwd`:/source \
       -v `pwd`/final/dist:/usr/local \
       nizq/ubuntu-pfq-build /source/build-pfq.sh sniffer
cp Dockerfile.sniffer final/Dockerfile
cd final
docker build -t nizq/pfq-sniffer .
