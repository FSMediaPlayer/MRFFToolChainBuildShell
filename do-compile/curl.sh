#! /usr/bin/env bash
#
# Copyright (C) 2024 FantasySwords <thinkcode@126.com>
# Copyright (C) 2021 Matt Reach<qianlongxu@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"
source ../tools/env_assert.sh

echo "=== [$0] check env begin==="
env_assert "XC_ARCH"
env_assert "XC_BUILD_NAME"
env_assert "XCRUN_CC"
env_assert "XC_DEPLOYMENT_TARGET"
env_assert "XC_BUILD_SOURCE"
env_assert "XC_BUILD_PREFIX"
env_assert "XCRUN_SDK_PATH"
env_assert "XC_THREAD"
env_assert "XC_PRODUCT_ROOT"
echo "XC_DEBUG:$XC_DEBUG"
echo "===check env end==="

# prepare build config
CFG_FLAGS="--prefix=$XC_BUILD_PREFIX --disable-dependency-tracking \
--disable-silent-rules \
 --enable-static \
 --disable-shared \
 --enable-ares \
 --with-zlib \
 --disable-ldap"

ssl_dir=$XC_PRODUCT_ROOT/openssl-$_XC_ARCH
if [[ -d $ssl_dir ]];then
    CFG_FLAGS="$CFG_FLAGS --with-openssl=$ssl_dir"
    echo "use openssl from $ssl_dir"
fi

CFLAGS="-arch $XC_ARCH $XC_DEPLOYMENT_TARGET $XC_OTHER_CFLAGS"

if [[ "$XC_DEBUG" == "debug" ]];then
   CFG_FLAGS="${CFG_FLAGS} use_examples=yes"
fi

# for cross compile
if [[ $(uname -m) != "$XC_ARCH" || "$XC_FORCE_CROSS" ]];then
    echo "[*] cross compile, on $(uname -m) compile $XC_PLAT $XC_ARCH."
    # https://www.gnu.org/software/automake/manual/html_node/Cross_002dCompilation.html
    CFLAGS="$CFLAGS -isysroot $XCRUN_SDK_PATH"
    CFG_FLAGS="$CFG_FLAGS --host=$XC_ARCH-apple-darwin --with-sysroot=$XCRUN_SDK_PATH"
fi

echo "----------------------"
echo "[*] configurate $LIB_NAME"
echo "----------------------"


cd $XC_BUILD_SOURCE

if [[ -f 'configure' ]]; then
   echo "reuse configure"
else
   echo "auto generate configure"
    autoreconf -fi
fi


echo 
echo "CC: $XCRUN_CC"
echo "CFG_FLAGS: $CFG_FLAGS"
echo "CFLAGS: $CFLAGS"
echo 

./configure $CFG_FLAGS \
   CC="$XCRUN_CC" \
   CFLAGS="$CFLAGS" \
   LDFLAGS="$CFLAGS" \
   >/dev/null

#----------------------
echo "----------------------"
echo "[*] compile $LIB_NAME"
echo "----------------------"

make

make install -j$XC_THREAD >/dev/null