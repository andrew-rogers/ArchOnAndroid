
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

aoa() {
  # Path for the user downloaded wget
  local WGET_DL="/sdcard/Download/wget-armeabi"

  local cmd=$1
  shift

  local WRITABLE_DIR=${AOA_DIR%/*}
  local UTILS_BIN=$AOA_DIR/utils/bin

  case $cmd in

    "cd" )
      if [ -d "$AOA_DIR" ]; then
        cd "$AOA_DIR"
      else
        cd "$WRITABLE_DIR"
      fi
    ;;

    "find_writable_install_dir" )
      # --- Find out where ArchOnAndroid can be installed ---
      # When deployed on an Android terminal app (eg. connectbot) it is
      # possible that the current directory is not writable. The terminal app's
      # install directory should be writable so we install there. However, we first
      # check if the current directory is writable.
      local here=${PWD%%/ArchOnAndroid*}
      if [ -w "$here" ]; then
        # We can write to the current dir so install here. This is useful for
        # installing and testing on non-Android systems.
        echo "$here";
      else
        # Find the directory of the terminal app. The terminal app may only be able 
        # to write to and execute from its directory or sub directory.
        echo "/data/data/$(cat /proc/$PPID/cmdline)"
      fi
    ;;

    "find_writable_download_dir" )
      # --- Find out where to cache downloads ---
      if [ -w "$HOME" ]; then
        echo "$HOME/.ArchOnAndroid/cache"
      elif [ -w "/sdcard" ]; then
        echo "/sdcard/ArchOnAndroid/cache"
      fi
    ;;

    "find_wget" )
      if [ -e "$UTILS_BIN/wget" ]; then
        echo "$UTILS_BIN/wget"
      elif [ -e "$WRITABLE_DIR/wget" ]; then
        echo "$WRITABLE_DIR/wget"
      else
        wget --version > /dev/null && echo "wget"
      fi
        
    ;;

    "install_wget" )
      if [ ! -e "$WRITABLE_DIR/wget" ]; then
        # not in $WRITABLE_DIR/wget so copy from download directory
        [ ! -f "$WGET_DL" ] && echo "Can't find: $WGET_DL" && return 1
        echo "Found wget at: $WGET_DL"
    
        # Android may not have cp, use cat
        cat "$WGET_DL" > "$WRITABLE_DIR/wget"
      fi
      chmod 755 "$WRITABLE_DIR/wget"
    ;;

    "check_wget" )
      $(aoa find_wget) --help > /dev/null 2>&1 || aoa install_wget
      aoa find_wget
    ;;

    "download" )
      local url=$1
      local dst_dir=$(aoa find_writable_download_dir)
      if [ -n "$2" ]; then
        dst_dir=$dst_dir/$2
      fi
      local fn=${url##*/} # Get the filename from the end of the URL.

      # Some Arch packages have + or : in them which are url encoded, decode them for filename.
      local fn1=$(echo "$fn" | sed "s/%2b/+/" | sed "s/%3a/:/" 2> /dev/null)
      [ -n "$fn1" ] && fn="$fn1";
      if [ -z "$fn" ]; then
        fn=index.html
      fi

      # If not already downloaded to cache then download
      if [ ! -e "$dst_dir/$fn" ]; then
        $(aoa find_wget) --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
      fi

      # If downloaded then return the path
      if [ -e "$dst_dir/$fn" ]; then
        echo "$dst_dir/$fn"
      fi
    ;;

    "get_script" )
      local script=$AOA_DIR/utils/$1.sh
      if [ ! -e "$script" ]; then
        script=$(aoa download https://github.com/andrew-rogers/ArchOnAndroid/raw/master/utils/$1.sh utils)
      fi
      shift
      echo "$script"
    ;;

    "set_ld" )
      # Only set LD_LIBRARY_PATH if wget wrapper exists
      if [ -f "$AOA_DIR/utils/bin/wget" ]; then
        export LD_LIBRARY_PATH=$AOA_DIR/lib
        export LD_PRELOAD=
      fi
    ;;

    "include_settings" )
      if [ -f "$AOA_DIR/etc/aoa-settings.sh" ]; then
        . "$AOA_DIR/etc/aoa-settings.sh"
      fi
    ;;

    * )
      # Run the second-stage script for commands not defined here
      local script=$(aoa get_script second-stage)
      local aoa_setup=$(aoa get_script aoa-setup)
      sh $script $aoa_setup $cmd $*
      aoa set_ld
      aoa include_settings
  esac
}

if [ -n "$AOA_SETUP" ]; then
  # AOA_SETUP is defined so therefore we are being sourced from another script
  WRITABLE_DIR=${AOA_DIR%/*}
  UTILS_BIN=$AOA_DIR/utils/bin
  AOA_CACHE=$(aoa find_writable_download_dir)
else
  export AOA_DIR=$(aoa find_writable_install_dir)/ArchOnAndroid
  export C_INCLUDE_PATH=$AOA_DIR/usr/include
  aoa check_wget #> /dev/null
  aoa second_stage_check
  aoa set_ld
  aoa include_settings
  cd $AOA_DIR
fi


