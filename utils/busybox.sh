
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
    # Create links for all apps except wget, the busybox wget doesn't work on android.
    if [ "$app" != "wget" ]; then
      aoa_busybox_symlink "$app"
    fi
  done
}

busybox_check() {
  busybox true 2> /dev/null
  if [ $? -ne 0 ]; then
    $UTILS_BIN/$BB true 2> /dev/null || aoa_busybox_install
  fi
}

