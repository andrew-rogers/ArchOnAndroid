
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

# Specify the wget filename when installed
WGET=wget

# Find the directory of the terminal app. The terminal app may only be able 
# to write to and execute from its directory or sub directory.
TERMAPP_DIR=/data/data/$(cat /proc/$PPID/cmdline)

AOA_DIR=$TERMAPP_DIR/aoa

aoa_wget_install() {
  if [ -e "$WGET_PATH" ]
  then
    chmod 755 "$WGET_PATH"
  else # not in $WGET_PATH so copy
    [ ! -f "$WGET_DL" ] && echo "Can't find: $WGET_DL" && return 1
    echo "Found wget at: $bb"
    
    # Android may not have cp, use cat
    cat "$WGET_DL" > "$TERMAPP_DIR/$WGET"
    chmod 755 "$TERMAPP_DIR/$WGET"
  fi
}

aoa_wget_check() {
  if [ -e "$AOA_DIR/utils/bin/$WGET" ]; then
    WGET_PATH=$AOA_DIR/utils/bin/$WGET
  fi
  
  $WGET_PATH --help > /dev/null || aoa_wget_install
}

aoa_wget() {
  local url=$1
  local dst_dir=$2
  $WGET_PATH --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
}

aoa_include() {
  aoa_wget https://github.com/andrew-rogers/ArchOnAndroid/raw/master/utils/$1.sh $AOA_DIR/utils
  . $AOA_DIR/utils/$1.sh
}

export WGET_PATH=$TERMAPP_DIR/$WGET
export AOA_DIR
aoa_wget_check
aoa_include second-stage
