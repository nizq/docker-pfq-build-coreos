#!/bin/sh

SOURCE=/source
BUILD=$SOURCE/build
LINUX=$SOURCE/linux
PFQ=$SOURCE/PFQ
FINAL=$SOURCE/final
PREFIX=/usr/local
KERNEL_VERSION=`uname -r`

export LANG=C.UTF-8

mkdir -p $BUILD
mkdir -p $FINAL

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
cp linux/pf_q.h $LINUX/include/linux
cp linux/pf_q-kcompat.h $LINUX/include/linux
mkdir -p $PREFIX/include/pfq/
cp Module.symvers $INSTDIR

USER=$PFQ/user
cd $USER/C
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install

cd $USER/C++/pfq
make install

for DIR in "Haskell" "irq-affinity" "pfq-load" "pfqd" "pfq-omatic" "pfq-stress"
do
    cd $USER/$DIR
    cabal configure --prefix=$PREFIX
    cabal build
    cabal install --prefix=$PREFIX
done

apk --update add linux-headers

cd $USER/tool
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install

cd $USER/libpcap/libpcap-1.7.4/
mkdir -p $PREFIX/include/linux
./configure --enable-pfq --prefix=$PREFIX
make && make install

# tar zcvf $FINAL/pfq-user.tar.gz $PREFIX
