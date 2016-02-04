#!/bin/bash

set -x

BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)
trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

function get_args() {
  test -f "$1" && LOCAL_PATH=$1 && TARBALL_PATH=$1 && return
  test -n "$1" && URL=$1
  if [[ $1 =~ ^perl[-]5 ]]; then
    URL="http://www.cpan.org/src/5.0/${1}.tar.bz2"
  fi
  test -z "$1" && URL="http://www.cpan.org/src/5.0/perl-5.22.0.tar.bz2"
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

test -x "/usr/bin/make" || sudo apt-get install build-essential zip unzip bzip2

TARBALL=$(basename $TARBALL_PATH)
VERSION=$(basename $TARBALL_PATH .tar.bz2)
PREFIX=$HOME/$VERSION

# die "\$URL: $URL, \$TARBALL_PATH: $TARBALL_PATH, \$LOCAL_PATH: $LOCAL_PATH"

cd "$BUILD_DIR"
test -f "$TARBALL_PATH" && echo untarring $TARBALL && tar -xjf "$TARBALL_PATH" && cd "$BUILD_DIR/$VERSION"
test -f Configure && ./Configure -des -Dprefix=$PREFIX -Dinc_version_list=none -Dprivlib=$PREFIX/lib -Darchlib=$PREFIX/lib -Dsitearch=$PREFIX/lib -Dsitelib=$PREFIX/lib && make
test -f Configure && test -f Makefile && test -n "$TEST_PERL" && make test
test -f Configure && test -x perl && make install
test -x "$PREFIX/bin/perl" && echo "PATH=$PREFIX/bin:$PATH"
