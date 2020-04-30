#!/bin/bash

LATEST_PERL_VERSION=5.30.2

set -x
# TEST_PERL=1
renice -n 19 -p $$

[[ -z "$BUILD_DIR" ]] && BUILD_DIR=$(mktemp -d /tmp/perl.XXXXXXXXX)
[[ -z "$DEST_DIR"  ]] && DEST_DIR=$HOME
trap "echo removing $BUILD_DIR...; rm -rf $BUILD_DIR; echo" EXIT

function get_args() {
  [[ -f "$1" ]] && LOCAL_PATH=$1 && TARBALL_PATH=$1 && return
  [[ -n "$1" ]] && URL=$1
  if [[ $1 =~ ^perl[-]5 ]]; then
    URL="https://www.cpan.org/src/5.0/${1}.tar.gz"
  elif [[ $1 =~ ^5.*[0-9] ]]; then
    URL="https://www.cpan.org/src/5.0/perl-${1}.tar.gz"
  fi
  [[ -z "$URL" ]] && URL="https://www.cpan.org/src/5.0/perl-${LATEST_PERL_VERSION}.tar.gz"
}

function get_vars() {
  [[ -n "$LOCAL_PATH" ]] && TARBALL=$(basename $TARBALL_PATH)
  [[ -n "$URL"        ]] && TARBALL=$(basename $URL)
}

function get_src() {
  [[ -z "$URL" ]] && return 0
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
[[ -x "/usr/bin/make" && -x '/usr/bin/cc' ]] || sudo apt-get install build-essential pkg-config autoconf zip unzip bzip2 libssl-dev zlib1g-dev libreadline-dev libexpat-dev libevent-dev libncurses-dev

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

pushd "$BUILD_DIR"
[[ -f "$TARBALL_PATH"    ]] && echo untarring $TARBALL && tar -xf "$TARBALL_PATH" && pushd "$BUILD_DIR/$VERSION"
[[ -f Configure          ]] && ./Configure -des -Dprefix=$PREFIX -Dinc_version_list=none -Dprivlib=$PREFIX/lib -Darchlib=$PREFIX/lib -Dsitearch=$PREFIX/lib -Dsitelib=$PREFIX/lib && make
[[ -n "$TEST_PERL"       ]] && [[ -f Makefile ]] && [[ -x perl ]] && make test && make install
[[ -z "$TEST_PERL"       ]] && [[ -f Makefile ]] && [[ -x perl ]] && make install
[[ -x "$PREFIX/bin/perl" ]] && echo -e "PATH=$PREFIX/bin:\$PATH\n$PREFIX/bin/cpan App::cpanminus && $PREFIX/bin/cpanm https://github.com/atomicstack/Task-BeLike-MATTK/archive/master.zip"
