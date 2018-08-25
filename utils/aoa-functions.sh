
#    ArchOnAndroid - setup ArchLinux package installer in a terminal app directory
#    Copyright (C) 2018  Andrew Rogers
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

CACHE_DIR="/sdcard/ArchOnAndroid/cache"
UTILS_BIN="$AOA_DIR/utils/bin"
SETTINGS="$AOA_DIR/etc/aoa-settings.sh"

. $AOA_DIR/utils/package-manager.sh

help()
{
    echo "Available commands:"
    echo "    install"
}

download()
{
  local url=$1
  local dst_dir="$CACHE_DIR"
  if [ -n "$2" ]; then
    dst_dir=$dst_dir/$2
  fi
  local fn=${url##*/} # Get the filename from the end of the URL.

  # Some Arch packages have + or : in them which are url encoded, decode them for filename.
  local fn1=$(echo "$fn" | sed "s/%2b/+/g" | sed "s/%3a/:/g" 2> /dev/null)
  [ -n "$fn1" ] && fn="$fn1";
  if [ -z "$fn" ]; then
    fn=index.html
  fi

  # If not already downloaded to cache then download
  if [ ! -e "$dst_dir/$fn" ]; then
    wget --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
  fi

  # If downloaded then return the path
  if [ -e "$dst_dir/$fn" ]; then
    echo "$dst_dir/$fn"
  fi
}

wget_wrapper()
{
  if [ ! -e "$UTILS_BIN/wget" ]; then
    mkdir -p "$UTILS_BIN"

    # Get the path to wget
    local wget_path=$(which wget)

    # Create wrapper for wget
    if [ -e "$wget_path" ]; then
      echo "#!$(which sh)" > $UTILS_BIN/wget
      echo "" >> $UTILS_BIN/wget
      echo "( unset LD_LIBRARY_PATH; $wget_path \$* )" >> $UTILS_BIN/wget
      chmod +x $UTILS_BIN/wget
    else
      echo "Can't find wget." >&2
    fi
  fi
}

# Add setting to global settings file.
add_setting()
{
  local name="export $1"
  local val="$2"
  local file="$AOA_DIR/etc/aoa-settings.sh"

  [ -z "$name" ] && return
  [ -z "$val" ] && return

  if [ -f "$file" ]; then
    # Check if variable name and val already in settings
    busybox grep "^$name=$val$" "$file" > /dev/null
    if [ $? -ne 0 ]; then
      # Check is variable name exists
      busybox grep "^$name=" "$file" > /dev/null
      if [ $? -eq 0 ]; then
        # Variable name exists so just substitute value
        sed -i "s|^$name=.*|$name=$val|" "$file"
      else
	# Variable doesn't exist so append
        echo "$name=$val" >> "$file"
      fi
    fi
  else
    # Settings file doesn't exist so create it and append
    mkdir -p "$AOA_DIR/etc"
    echo "$name=$val" > "$file"
  fi
}

get_setting()
{
  local name="export $1"
  if [ -f "$SETTINGS" ]; then
    local line="$(grep "^$name=" "$SETTINGS")"
    echo "$line" | sed "s|^$name=||"
  fi
}

add_path()
{
  # Check if PATH exists in settings
  local path="$(get_setting PATH)"
  if [ -z "$path" ]; then
    # Create new PATH
    path="$PATH"
  fi

  # Check if already in PATH
  echo "$path" | grep "$1" > /dev/null
  if [ $? -ne 0 ]; then
    # Not in PATH
    add_setting "PATH" "$1:$path"
  fi
}

create_settings()
{
  add_path "$AOA_DIR/usr/bin"
  add_path "$UTILS_BIN"
  add_setting "LD_LIBRARY_PATH" "$AOA_DIR/lib"
  add_setting "LD_PRELOAD" "''"
}

$CMD $*

