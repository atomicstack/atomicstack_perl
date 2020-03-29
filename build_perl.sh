#!/bin/bash

LATEST_PERL_VERSION=5.30.2

set -x

[[ -z "$BUILD_DIR" ]] && BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)
[[ -z "$DEST_DIR"  ]] && DEST_DIR=$HOME
trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

function get_args() {
  test -f "$1" && LOCAL_PATH=$1 && TARBALL_PATH=$1 && return
  test -n "$1" && URL=$1
  if [[ $1 =~ ^perl[-]5 ]]; then
    URL="https://www.cpan.org/src/5.0/${1}.tar.bz2"
  fi
  test -z "$URL" && URL="https://www.cpan.org/src/5.0/perl-${LATEST_PERL_VERSION}.tar.gz"
}

function get_vars() {
  test -n "$LOCAL_PATH" && TARBALL=$(basename $TARBALL_PATH)
  test -n "$URL"        && TARBALL=$(basename $URL)
}

function get_src() {
  test -z "$URL" && return 0
  TARBALL_PATH="$BUILD_DIR/$TARBALL"
  echo "fetching URL $URL..."
  wget -O "$TARBALL_PATH" $URL 2>/dev/null || curl $URL > "$TARBALL_PATH" 2>/dev/null
}

function die() {
  echo $* 1>&2
  exit 1
}

get_args $1
get_vars
get_src

# assuming this is a freshly built debian box...
( test -x "/usr/bin/make" && test -x '/usr/bin/cc' ) || sudo apt-get install build-essential pkg-config autoconf zip unzip bzip2 libssl-dev zlib1g-dev libreadline-dev libexpat-dev libevent-dev libncurses-dev

TARBALL=$(basename $TARBALL_PATH)
if [[ "$TARBALL_PATH" =~ [.]tar[.]gz$ ]]; then
    VERSION=$(basename $TARBALL_PATH .tar.gz)
    # TAR_DECOMPRESS_PARAM=z
elif [[ "$TARBALL_PATH" =~ [.]tar[.]bz2$ ]]; then
    VERSION=$(basename $TARBALL_PATH .tar.bz2)
    # TAR_DECOMPRESS_PARAM=j
else
    die "don't know how to strip extension from $TARBALL_PATH"
fi
PREFIX=$HOME/$VERSION

# die "\$URL: $URL, \$TARBALL_PATH: $TARBALL_PATH, \$LOCAL_PATH: $LOCAL_PATH"

cd "$BUILD_DIR"
test -f "$TARBALL_PATH" && echo untarring $TARBALL && tar -${TAR_DECOMPRESS_PARAM}xf "$TARBALL_PATH" && cd "$BUILD_DIR/$VERSION"
test -f Configure && ./Configure -des -Dprefix=$PREFIX -Dinc_version_list=none -Dprivlib=$PREFIX/lib -Darchlib=$PREFIX/lib -Dsitearch=$PREFIX/lib -Dsitelib=$PREFIX/lib && make
test -f Configure && test -f Makefile && test -n "$TEST_PERL" && make test
test -f Configure && test -x perl && make install
test -x "$PREFIX/bin/perl" && echo -e "PATH=$PREFIX/bin:$PATH\n$PREFIX/bin/cpan App::cpanminus && $PREFIX/bin/cpanm https://github.com/atomicstack/Task-BeLike-MATTK/archive/master.zip"
