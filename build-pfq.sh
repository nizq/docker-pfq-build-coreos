#!/bin/bash

case "$1" in
    admin) mode="admin"
           ;;
    sniffer) mode="sniffer"
             ;;
    *) echo "Invalid option: use 'admin' or 'sniffer'"
       exit 1
       ;;
esac

SOURCE=/source
BUILD=$SOURCE/build
LINUX=$SOURCE/linux
PFQ=$SOURCE/PFQ
PREFIX=/usr/local

KERNEL_VERSION=`uname -r`
HEADER_VERSION=4.2.0-25
TCPDUMP_VERSION=4.7.4
PFQ_VERSION=5.22.11
BRO_VERSION=2.4.1

export LANG=C.UTF-8

cd $LINUX
git checkout v`uname -r|sed 's/-r[0-9]$//'`

zcat /proc/config.gz > .config
make modules_prepare
sed -i "s/4.2.2+/${KERNEL_VERSION}/g" include/generated/utsrelease.h

cd $PFQ
if  [[ $mode = "admin" ]]; then
    echo "export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH" >> ~/.bashrc 
    export PATH=~/.cabal/bin:/opt/cabal/1.20/bin:/opt/ghc/7.8.4/bin:$PATH 
    cabal update 
    cabal install alex happy
    cabal install --only-dep --force-reinstalls pfq-framework.cabal
fi

cd $PFQ/kernel
INSTDIR=$PREFIX/kernel/$KERNEL_VERSION
mkdir -p $INSTDIR
make -C $LINUX M=$PWD modules
cp  pfq.ko $INSTDIR
mkdir -p $PREFIX/include/pfq/
cp -r linux $PREFIX/include/
cp Module.symvers $INSTDIR

USER=$PFQ/user
cd $USER/C
cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
make && make install && ldconfig -v

if  [[ $mode = "admin" ]]; then
    for DIR in "Haskell" "irq-affinity" "pfq-load" "pfq-omatic" "pfq-stress"
    do
        echo "==> Building $USER/$DIR..."
        cd $USER/$DIR
        cabal install --prefix=$PREFIX \
              --extra-include-dirs=$PREFIX/include \
              --extra-lib-dirs=$PREFIX/lib
    done

    # use default PFQDaemon.hs to compile pfqd
    cd $USER/pfqd
    rm -f src/PFQDaemon.hs
    cp $SOURCE/PFQDaemon.hs src
    cabal install --prefix=$PREFIX \
          --extra-include-dirs=$PREFIX/include \
          --extra-lib-dirs=$PREFIX/lib

    cd $USER/tool
    cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX .
    make && make install
fi

if  [[ $mode = "sniffer" ]]; then
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

    # # build bro
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
fi
