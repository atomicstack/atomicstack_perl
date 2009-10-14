#!/bin/bash

URL=$1
test -z "$URL" && URL="http://mirror.internode.on.net/pub/cpan/authors/id/D/DA/DAPM/perl-5.10.1.tar.bz2"

test -x "/usr/bin/make" || sudo apt-get install build-essential zip unzip bzip2

TARBALL=$(basename $URL)
VERSION=$(basename $TARBALL .tar.bz2)
PREFIX=$HOME/$VERSION

BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)
trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

cd "$BUILD_DIR" && ( wget -O "$BUILD_DIR/$TARBALL" $URL 2>/dev/null || curl $URL > "$BUILD_DIR/$TARBALL" 2>/dev/null )
test -f "$TARBALL" && echo untarring $TARBALL && tar -xjf "$BUILD_DIR/$TARBALL" && cd "$BUILD_DIR/$VERSION"
test -f Configure && ./Configure -des -Dprefix=$PREFIX -Dinc_version_list=none -Dprivlib=$PREFIX/lib -Darchlib=$PREFIX/archlib -Dsitearch=$PREFIX/archlib -Dsitelib=$PREFIX/lib && make
test -f Configure && test -f Makefile && test -n "$TEST_PERL" && make test
test -f Configure && test -x perl && make install
test -x "$HOME/$VERSION/bin/perl" && echo "PATH=$HOME/$VERSION/bin:$PATH"
