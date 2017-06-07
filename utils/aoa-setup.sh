
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

# Specify the wget filename as in the /sdcard/Download directory.
WGET_DL=/sdcard/Download/wget-armeabi

# Find the directory of the terminal app. The terminal app may only be able 
# to write to and execute from its directory or sub directory.
TERMAPP_DIR=/data/data/$(cat /proc/$PPID/cmdline)

AOA_DIR=$TERMAPP_DIR/aoa
UTILS_BIN=$AOA_DIR/utils/bin
RET_STR=""

aoa_wget_install() {
  if [ -e "$TERMAPP_DIR/wget" ]
  then
    chmod 755 "$TERMAPP_DIR/wget"
  else # not in $TERMAPP_DIR/wget so copy from download directory
    [ ! -f "$WGET_DL" ] && echo "Can't find: $WGET_DL" && return 1
    echo "Found wget at: $bb"
    
    # Android may not have cp, use cat
    cat "$WGET_DL" > "$TERMAPP_DIR/wget"
    chmod 755 "$TERMAPP_DIR/wget"
  fi
}

aoa_wget_find() {
  RET_STR=""
  if [ -e "$UTILS_BIN/wget" ]; then
    RET_STR=$UTILS_BIN/wget
  elif [ -e "$TERMAPP_DIR/wget" ]; then
    RET_STR=$TERMAPP_DIR/wget
  fi
}

aoa_wget_check() {
  aoa_wget_find
  $RET_STR --help > /dev/null || aoa_wget_install
}

aoa_wget() {
  local url=$1
  local dst_dir=$2
  aoa_wget_find
  $RET_STR --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
}

aoa_include() {
  aoa_wget https://github.com/andrew-rogers/ArchOnAndroid/raw/master/utils/$1.sh $AOA_DIR/utils
  . $AOA_DIR/utils/$1.sh
}

export AOA_DIR
aoa_wget_check
aoa_include second-stage
