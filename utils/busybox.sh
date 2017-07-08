
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

# Specify the busybox filenames that might already be in cache directory.
BB_DLS="$AOA_CACHE/busybox-armv7l
$AOA_CACHE/busybox-armv6l"

# Specify busybox URLs
BB_URLS="https://github.com/windflyer/android_binaries/raw/master/busybox-armv7l
https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"

# Specify the busybox filename when installed
BB=busybox

aoa_busybox_downloaded() {
  local bb
  echo "$BB_DLS" | while read -r bb
  do
    [ -e "$bb" ] && echo "$bb" && return 0
  done
  return 1
}

aoa_busybox_find() {

  # Check if busybox already downloaded
  BB_DL=$(aoa_busybox_downloaded)

  if [ ! -e "$BB_DL" ]; then

    # If we get here then assume we need to download busybox
    local bb
    echo "$BB_URLS" | while read -r bb
    do
      aoa download $bb && break
    done

    BB_DL=$(aoa_busybox_downloaded)
  fi
}

aoa_busybox_install() {
  if [ -e "$UTILS_BIN/$BB" ]
  then
    chmod 755 "$UTILS_BIN/$BB"
  else # not in $UTILS_BIN/$BB so copy
    aoa_busybox_find
    [ ! -f "$BB_DL" ] && error "Can't find: $BB" && return 1
    msg "Found busybox at: $BB_DL"
    
    # Android may not have cp, use cat
    cat "$BB_DL" > "$WRITABLE_DIR/$BB"
    chmod 755 "$WRITABLE_DIR/$BB"

    # if $UTILS_BIN dir doesn't exist create it
    [ -e "$UTILS_BIN" ] || $WRITABLE_DIR/$BB mkdir -p "$UTILS_BIN"

    # mv busybox to $UTILS_BIN dir
    cat "$WRITABLE_DIR/$BB" > "$UTILS_BIN/$BB"
    chmod 755 "$UTILS_BIN/$BB"
    [ -e "$UTILS_BIN/$BB" ] && $UTILS_BIN/$BB rm "$WRITABLE_DIR/$BB"
    [ -e "$UTILS_BIN/$BB" ] && msg "Relocated busybox to: $UTILS_BIN/$BB"
  fi
  
  msg "Making symlinks for busybox applets, could take a while."
  aoa_busybox_symlinks
  aoa_busybox_replace_wget
}

aoa_busybox_replace_wget() {
  local WGET_PATH=$UTILS_BIN/wget-bin
  $UTILS_BIN/$BB rm $UTILS_BIN/wget
  if [ -e "/usr/bin/wget" ]; then
    WGET_PATH=/usr/bin/wget 
  elif [ -e "$WRITABLE_DIR/wget" ]; then
    # Move the Android compatible wget
    $UTILS_BIN/$BB mv $WRITABLE_DIR/wget $WGET_PATH
  fi

  # Create wrapper for wget
  echo "#!$UTILS_BIN/sh" > $UTILS_BIN/wget
  echo "" >> $UTILS_BIN/wget
  echo "( unset LD_LIBRARY_PATH; $WGET_PATH \$* )" >> $UTILS_BIN/wget
  $UTILS_BIN/$BB chmod +x $UTILS_BIN/wget
}

aoa_busybox_symlink() {
  if [ ! -e "$UTILS_BIN/$1" ]; then
    local pdir=$PWD
    cd "$UTILS_BIN"
    $UTILS_BIN/$BB ln -s $BB $1
    cd "$pdir"
  fi
}

aoa_busybox_symlinks() {
  for app in $($UTILS_BIN/$BB --list)
  do
    aoa_busybox_symlink "$app"
  done
}

busybox_check() {
  $UTILS_BIN/$BB true 2> /dev/null || aoa_busybox_install
}

