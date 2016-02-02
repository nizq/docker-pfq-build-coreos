#!/bin/sh

docker build -t nizq/ubuntu-pfq-build .
docker run -it --rm -v `pwd`:/source -v `pwd`/final/dist:/opt/pfq nizq/ubuntu-pfq-build /source/build-pfq.sh

cp Dockerfile.final final/Dockerfile
cd final
docker build -t nizq/pfq .
