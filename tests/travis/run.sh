#!/bin/sh

set -e
set -x

export PATH=$HOME/opt/bin:$PATH

export PYCURL_VSFTPD_PATH=$HOME/opt/bin/vsftpd

if test -n "$USECURL"; then
  curldirname=curl-"$USECURL"
  export PYCURL_CURL_CONFIG="$HOME"/opt/$curldirname/bin/curl-config
  $PYCURL_CURL_CONFIG --features
  export LD_LIBRARY_PATH="$HOME"/opt/$curldirname/lib
fi

setup_args=
if test -n "$USESSL"; then
  if test "$USESSL" = libressl; then
    export PYCURL_SSL_LIBRARY=openssl
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/opt/libressl-$USELIBRESSL/lib"
    setup_args="$setup_args --openssl-dir=$HOME/opt/libressl-$USELIBRESSL"
  elif test "$USESSL" != none; then
    export PYCURL_SSL_LIBRARY="$USESSL"
    if test -n "$USEOPENSSL"; then
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/opt/openssl-$USEOPENSSL/lib"
      setup_args="$setup_args --openssl-dir=$HOME/opt/openssl-$USEOPENSSL"
    fi
    if test -n "$USELIBRESSL"; then
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/opt/libressl-$USELIBRESSL/lib"
    fi
  fi
elif test -z "$USECURL"; then
  # default for ubuntu 12 is openssl
  # default for ubuntu 14 which is what travis currently uses is gnutls
  export PYCURL_SSL_LIBRARY=gnutls
fi

if test -n "$AVOIDSTDIO"; then
  export PYCURL_SETUP_OPTIONS=--avoid-stdio
fi

make gen
python setup.py build $setup_args

(cd tests/fake-curl/libcurl && make)

ldd build/lib*/pycurl*.so

./tests/run.sh
./tests/ext/test-suite.sh

if test -n "$TESTDOCSEXAMPLES"; then
  which pyflakes
  pyflakes python examples tests setup.py winbuild.py
  ./tests/run-quickstart.sh

  # sphinx requires python 2.7+ or 3.3+
  make docs
fi
