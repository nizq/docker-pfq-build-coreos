#!/bin/sh

SOURCE=/source
BUILD=$SOURCE/build
LINUX=$SOURCE/linux
PFQ=$SOURCE/PFQ
FINAL=$SOURCE/final
DIST=$SOURCE/dist
PREFIX=/usr/local

KERNEL_VERSION=`uname -r`
HEADER_VERSION=4.2.0-25
TCPDUMP_VERSION=4.7.4
PFQ_VERSION=5.22.11
BRO_VERSION=2.4.1

export LANG=C.UTF-8

mkdir -p $BUILD
mkdir -p $FINAL
rm -rf $DIST
mkdir -p $DIST

echo "export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH" >> ~/.bashrc 
export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH 
cabal update 
cabal install alex happy

cd $LINUX
git checkout v`uname -r|sed 's/-r[0-9]$//'`

zcat /proc/config.gz > .config
make modules_prepare
sed -i "s/4.2.2+/${KERNEL_VERSION}/g" include/generated/utsrelease.h

cd $PFQ
cabal install --only-dep --force-reinstalls pfq-framework.cabal

cd $PFQ/kernel
INSTDIR=$PREFIX/kernel/$KERNEL_VERSION
mkdir -p $INSTDIR
make -C $LINUX M=$PWD modules
cp  pfq.ko $INSTDIR
mkdir -p $PREFIX/include/pfq/
cp -r linux $PREFIX/include/
cp Module.symvers $INSTDIR

apt-get install -y linux-headers-${HEADER_VERSION}-generic

USER=$PFQ/user
cd $USER/C
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install

for DIR in "Haskell" "irq-affinity" "pfq-load" "pfqd" "pfq-omatic" "pfq-stress"
do
    cd $USER/$DIR
    cabal install --prefix=$PREFIX \
          --extra-include-dirs=$PREFIX/include \
          --extra-lib-dirs=$PREFIX/lib
done

cd $USER/tool
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install

# libpcap
cd $USER/libpcap/libpcap-1.7.4/
./configure --enable-pfq --prefix=$PREFIX
make && make install

# build tcpdump
cd $BUILD
wget -c http://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz
tar zxvf tcpdump-${TCPDUMP_VERSION}.tar.gz
cd tcpdump-${TCPDUMP_VERSION}
./configure && make && make install

# build bro
cd $BUILD
wget -c https://www.bro.org/downloads/release/bro-${BRO_VERSION}.tar.gz
tar zxvf bro-${BRO_VERSION}.tar.gz
cd bro-${BRO_VERSION}
./configure --prefix=$PREFIX \
            --disable-broctl \
            --disable-broccoli \
            --disable-auxtools
make
make install
strip -s $PREFIX/bin/bro
