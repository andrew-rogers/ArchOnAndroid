
#    ArchOnAndroid - setup ArchLinux package installer in a terminal app directory
#    Copyright (C) 2017  Andrew Rogers
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Path for the user downloaded wget
WGET_DL="/sdcard/Download/wget-armeabi"

# --- Find out where ArchOnAndroid can be installed ---
# When deployed on an Android terminal app (eg. connectbot) it is
# possible that the current directory is not writable. The terminal app's
# install directory should be writable so we install there. However, we first
# check if the current directory is writable.
if [ -w "$PWD" ]; then
  # We can write to the current dir so install here. This is useful for
  # installing and testing on non-Android systems.
  WRITABLE_DIR=$PWD;
else
  # Find the directory of the terminal app. The terminal app may only be able 
  # to write to and execute from its directory or sub directory.
  WRITABLE_DIR=/data/data/$(cat /proc/$PPID/cmdline)
fi

# --- Find out where to cache downloads ---
if [ -w "$HOME" ]; then
  AOA_CACHE=$HOME/.ArchOnAndroid/cache
elif [ -w "/sdcard" ]; then
  AOA_CACHE=/sdcard/ArchOnAndroid/cache
fi

AOA_DIR=$WRITABLE_DIR/ArchOnAndroid
UTILS_BIN=$AOA_DIR/utils/bin
RET_STR=""

aoa_wget_install() {
  if [ -e "$WRITABLE_DIR/wget" ]; then
    chmod 755 "$WRITABLE_DIR/wget"
  else # not in $WRITABLE_DIR/wget so copy from download directory
    [ ! -f "$WGET_DL" ] && echo "Can't find: $WGET_DL" && return 1
    echo "Found wget at: $WGET_DL"
    
    # Android may not have cp, use cat
    cat "$WGET_DL" > "$WRITABLE_DIR/wget"
    chmod 755 "$WRITABLE_DIR/wget"
  fi
}

aoa_wget_find() {
  RET_STR=""
  if [ -e "$UTILS_BIN/wget" ]; then
    RET_STR=$UTILS_BIN/wget
  elif [ -e "$WRITABLE_DIR/wget" ]; then
    RET_STR=$WRITABLE_DIR/wget
  elif [ -e "/usr/bin/wget" ]; then
    RET_STR=/usr/bin/wget
  fi
}

aoa_wget_check() {
  aoa_wget_find
  $RET_STR --help > /dev/null || aoa_wget_install
}

aoa_download() {
  RET_STR=""
  local url=$1
  local dst_dir=$AOA_CACHE/$2
  local fn=${url##*/} # Get the filename from the end of the URL.

  # If not already downloaded to cache then download
  if [ ! -e "$dst_dir/$fn" ]; then
    aoa_wget_find
    $RET_STR --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
  fi

  # If downloaded then return the path
  if [ -e "$dst_dir/$fn" ]; then
    RET_STR="$dst_dir/$fn"
  fi
}

aoa_include() {
  if [ ! -e "$AOA_DIR/utils/$1.sh" ]; then
    aoa_download https://github.com/andrew-rogers/ArchOnAndroid/raw/master/utils/$1.sh utils
    . $RET_STR
  else
  . $AOA_DIR/utils/$1.sh
  fi
}

export AOA_DIR
aoa_wget_check
aoa_include second-stage
