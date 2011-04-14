
#!/bin/bash

function die() {
  echo "$1" 1>&2
  exit 1
}

URL=$1
test -z "$URL" && URL="http://cpan.weepeetelecom.nl/src/perl-5.12.3.tar.bz2"

test -x "/usr/bin/make" || sudo apt-get install build-essential zip unzip bzip2

TARBALL=$(basename $URL)
VERSION=$(basename $TARBALL .tar.bz2)
PREFIX=$HOME/$VERSION
PERL_LIB=$PREFIX/lib
ARCH_LIB=$PREFIX/archlib
BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)

trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

cd "$BUILD_DIR" && ( wget -O "$BUILD_DIR/$TARBALL" $URL || curl $URL > "$BUILD_DIR/$TARBALL" )
( test -f "$TARBALL" && test -s "$TARBALL" ) || die "can't find $TARBALL"

echo untarring $TARBALL && tar -xjf "$BUILD_DIR/$TARBALL" && cd "$BUILD_DIR/$VERSION"
test -f Configure || die "can't find Configure in $PWD"

./Configure                         \
  -des                              \
  -Dusedevel                        \
  -Dprefix=$PREFIX                  \
  -Dinc_version_list=none           \
  -Dprivlib=$PERL_LIB               \
  -Dsitelib=$PERL_LIB               \
  -Darchlib=$ARCH_LIB               \
  -Dsitearch=$ARCH_LIB

test -f Makefile || die "can't find Makefile in $PWD"

make
test -x perl || die "can't find freshly built perl binary in $PWD"

test -n "$TEST_PERL" && ( make test || die "test suite failed" )

make install
test -x "$PREFIX/bin/perl" || die "can't find installed perl binary in $PREFIX/bin"

echo "export PATH=$PREFIX/bin:$PATH"
