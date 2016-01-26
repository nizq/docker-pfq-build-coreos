FROM alpine:latest

COPY repositories /etc/apk/
RUN apk add --update curl xz alpine-sdk perl gmp-dev file gmp openssh openssl \
                     zlib-dev strace vim less jq ncurses-dev bash autoconf \
                     gcc make bc git cmake g++ flex bison

WORKDIR /build
COPY ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz build.mk fix-execvpe-signature-ghc-7.8.4.patch /build/
RUN wget https://nixos.org/releases/patchelf/patchelf-0.8/patchelf-0.8.tar.bz2 \
    && tar xfj patchelf-0.8.tar.bz2 \
    && cd patchelf-0.8 \
    && ./configure && make install \
    && cd .. \
    && rm -rf patchelf* \
    && tar -xvJ -C / -f /build/ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz

WORKDIR /build/ghc
RUN wget https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-src.tar.bz2 \
    && tar xvfj ghc-7.8.4-src.tar.bz2

WORKDIR /build/ghc/ghc-7.8.4
ENV OLDPATH=$PATH PATH=/opt/ghc-cross/bin:$PATH
RUN cp /build/build.mk mk/build.mk \
    && patch -p1 < /build/fix-execvpe-signature-ghc-7.8.4.patch \
    && ./configure \
    && sed -i 's,chmod,sed -i s/__gnu_linux__/1/ libffi/build/src/closures.c \&\& chmod,' libffi/ghc.mk \
    && make -j8 \
    && make binary-dist

WORKDIR /build
RUN mv ghc/ghc-7.8.4/ghc-7.8.4-x86_64-unknown-linux.tar.bz2 . \
    && rm -rf ghc /opt/ghc-cross \
    && tar xvfj ghc-7.8.4-x86_64-unknown-linux.tar.bz2 \
    && cd ghc-7.8.4 \
    && ./configure \
    && sed -i '/C\ compiler\ link/{ s/""/"--no-pie"/ }' settings \
    && make install \
    && cd /tmp \
    && rm -rf ghc-7.8.4 ghc-7.8.4-x86_64-unknown-linux.tar.bz2

WORKDIR /build
ENV PATH=/root/.cabal/bin:$OLDPATH
RUN wget https://hackage.haskell.org/package/cabal-install-1.22.4.0/cabal-install-1.22.4.0.tar.gz \
    && tar xvfz cabal-install-1.22.4.0.tar.gz \
    && cd cabal-install-1.22.4.0 \
    && EXTRA_CONFIGURE_OPTS=--disable-library-profiling ./bootstrap.sh

WORKDIR /
RUN rm -rf /root/.ghc /build /root/.cabal/lib /root/.cabal/share

VOLUME ["/source"]
