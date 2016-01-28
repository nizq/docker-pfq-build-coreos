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

export LANG=C.UTF-8

mkdir -p $BUILD
mkdir -p $FINAL
rm -rf $DIST
mkdir -p $DIST

cd $LINUX
git checkout v4.2.2-coreos

zcat /proc/config.gz > .config
make modules_prepare

cabal update
cabal install alex happy

cd $PFQ
patch -p1 < ../fix-caddr.patch
cabal install --only-dep --force-reinstalls pfq-framework.cabal

cd $PFQ/kernel
INSTDIR=$FINAL/kmod/$KERNELVERSION
mkdir -p $INSTDIR
make -C $LINUX M=$PWD modules
cp  pfq.ko $INSTDIR
gzip -c pfq.ko | base64 > $INSTDIR/pfq.ko.gz
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

cd $USER/C++/pfq
make install
mkdir -p $DIST/libpfq++
make INSTDIR=$DIST/libpfq++/usr/local/include/pfq

for DIR in "Haskell" "irq-affinity" "pfq-load" "pfqd" "pfq-omatic" "pfq-stress"
do
    cd $USER/$DIR
    cabal configure --prefix=$PREFIX \
                    --extra-include-dirs=/usr/local/include \
                    --extra-lib-dirs=/usr/local/lib
    cabal build -v
    cabal install --prefix=$PREFIX
done

# INCLUDE_DIRECTORIES
cd $USER/tool
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install

cd $USER/libpcap/libpcap-1.7.4/
mkdir -p $PREFIX/include/linux
./configure --enable-pfq --prefix=$PREFIX
make && make install
make DESTDIR=$DIST/libpcap install

# make pfq-utils package
tar Jcvf $FINAL/pfq-tools-${PFQ_VERSION}.tar.xz $PREFIX/bin

# make libpfq package
cd $DIST/libpfq
tar Jcvf $FINAL/libpfq-${PFQ_VERSION}.tar.xz usr

# make c++ header package
cd $DIST/libpfq++
tar Jcvf $FINAL/libpfq++-dev.tar.xz usr

# build tcpdump
cd $BUILD
wget http://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz
tar zxvf tcpdump-${TCPDUMP_VERSION}.tar.gz
cd tcpdump-${TCPDUMP_VERSION}
./configure && make && make install
tar Jcvf $FINAL/tcpdump-bin-${TCPDUMP_VERSION}.tar.xz /usr/local/sbin/tcpdump
