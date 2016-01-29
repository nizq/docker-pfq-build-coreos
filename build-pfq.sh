#!/bin/sh

SOURCE=/source
BUILD=$SOURCE/build
LINUX=$SOURCE/linux
PFQ=$SOURCE/PFQ
FINAL=$SOURCE/final
DIST=$SOURCE/dist
PREFIX=/usr/local

KERNEL_VERSION=`uname -r`
TCPDUMP_VERSION=4.7.4
PFQ_VERSION=5.22.11
BRO_VERSION=2.4.1

export LANG=C.UTF-8

mkdir -p $BUILD
mkdir -p $FINAL
rm -rf $DIST
mkdir -p $DIST

cd $LINUX
git checkout v4.2.2-coreos

zcat /proc/config.gz > .config
make modules_prepare
sed -i "s/4.2.2+/${KERNEL_VERSION}/g" include/generated/utsrelease.h

cabal update
cabal install alex happy

cd $PFQ
patch -p1 < $SOURCE/fix-caddr.patch
cabal install --only-dep --force-reinstalls pfq-framework.cabal

cd $PFQ/kernel
INSTDIR=$FINAL/kmod/$KERNEL_VERSION
mkdir -p $INSTDIR
make -C $LINUX M=$PWD modules
cp  pfq.ko $INSTDIR
mkdir -p $PREFIX/include/pfq/
cp -r linux $PREFIX/include/
cp Module.symvers $INSTDIR

apk --update add linux-headers

USER=$PFQ/user
cd $USER/C
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install
mkdir -p $DIST/libpfq
make DESTDIR=$DIST/libpfq install
cd $DIST/libpfq
tar Jcvf $FINAL/libpfq-${PFQ_VERSION}.tar.xz usr

cd $USER/C++/pfq
make install
mkdir -p $DIST/libpfq++
make INSTDIR=$DIST/libpfq++/usr/local/include/pfq
cd $DIST/libpfq++
tar Jcvf $FINAL/libpfq++-dev.tar.xz usr

for DIR in "Haskell" "irq-affinity" "pfq-load" "pfqd" "pfq-omatic" "pfq-stress"
do
    cd $USER/$DIR
    cabal configure --prefix=$PREFIX \
                    --extra-include-dirs=/usr/local/include \
                    --extra-lib-dirs=/usr/local/lib
    cabal build -v
    cabal install --prefix=$PREFIX
done

cd $USER/tool
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install
tar Jcvf $FINAL/pfq-tools-${PFQ_VERSION}.tar.xz $PREFIX/bin

# libpcap
cd $USER/libpcap/libpcap-1.7.4/
mkdir -p $PREFIX/include/linux
./configure --enable-pfq --prefix=$PREFIX
make && make install
make DESTDIR=$DIST/libpcap install
cd $DIST/libpcap
tar Jcvf $FINAL/libpcap-1.7.4.tar.xz usr --exclude=/usr/local/share

# build tcpdump
cd $BUILD
wget http://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz
tar zxvf tcpdump-${TCPDUMP_VERSION}.tar.gz
cd tcpdump-${TCPDUMP_VERSION}
./configure && make && make install
tar Jcvf $FINAL/tcpdump-bin-${TCPDUMP_VERSION}.tar.xz /usr/local/sbin/tcpdump

# build bro
cd $BUILD
apk add geoip-dev fts fts-dev python-dev openssl-dev
wget wget https://www.bro.org/downloads/release/bro-${BRO_VERSION}.tar.gz
tar zxvf bro-${BRO_VERSION}.tar.gz
cd bro-${BRO_VERSION}
patch -p1 < $SOURCE/bro-musl.patch
cd aux/binpac
patch -p1 < $SOURCE/binpac-musl.patch
cd ../../
cp $SOURCE/FindFTS.cmake cmake
./configure --prefix=$PREFIX \
            --disable-broctl \
            --disable-broccoli \
            --disable-auxtools \
            --disable-debug
make
make DESTDIR=$DIST/bro/ install
cd $DIST/bro
strip -s usr/local/bin/bro
tar Jcvf $FINAL/bro-bin-${BRO_VERSION}.tar.xz usr
