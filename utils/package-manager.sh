
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

REPS=$(echo -e "community\nextra\ncore")
PKG_DIR=$(aoa find_writable_download_dir)/packages
URL_BASE="http://mirror.archlinuxarm.org/aarch64"

install() {
  local pkg=$1
  local fn=""
  local fl=$AOA_DIR/pkginfo/$pkg.files
  mkdir -p $AOA_DIR/pkginfo
  if [ -f "$fl" ]; then
    msg "Already installed: $1"
  else
    get_package_rep_and_filename $pkg
    if [ -n "$PKG_FILENAME" ]; then
      fn=$(aoa download $URL_BASE/$PKG_REP/$PKG_FILENAME packages/$PKG_REP)
    fi
    if [ -z "$fn" ]; then
      msg "Could not find '$pkg', try running 'aoa update' and check package name."
    else
      # The actual package expansion
      local pdir=$PWD
      cd $AOA_DIR
      xzcat $fn | tar -xv > "$fl"
      mv .PKGINFO "pkginfo/$1.PKGINFO"
      cd $pdir
    fi
  fi
}

update() {
  get_package_lists
}

get_db() {
  local db=$(aoa download http://mirror.archlinuxarm.org/aarch64/$1/$1.db packages)
  if [ -f "$db" ]; then
    local pdir=$PWD
    local db_dir=$AOA_DIR/var/lib/pacman/sync/$1.d
    mkdir -p "$db_dir"
    cd "$db_dir"
    echo "Extracting $1 packages database."
    tar -zxvf "$db" > /dev/null
  fi
}

get_index() {
  aoa download http://mirror.archlinuxarm.org/aarch64/core/ packages/core
}

get_hrefs() {
  local url=$1
  echo $url | busybox grep '://' || url=http://mirror.archlinuxarm.org/$url
  wget $url -O - 2> /dev/null | sed -n "s|.*href=\"||p" | sed "s|\".*||" | sed "s|^./||"
}

get_package_list() {
  local rep=$1
  mkdir -p $PKG_DIR
  get_hrefs aarch64/$rep > $PKG_DIR/$rep.lst
}

get_package_lists() {
  for rep in $REPS; do
    get_package_list $rep
  done
}

get_package_filename() {
  local rep=$1
  local pkg=$2
  local lst=$PKG_DIR/$rep.lst
  if [ ! -f "$lst" ]; then
    get_package_list $rep
  fi
  cat $lst  | busybox grep "^$pkg-[0-9].*[.]xz$"
}

# These global variables get set by functions below
PKG_REP=""
PKG_FILENAME=""

get_package_rep_and_filename() {
  local pkg=$1
  local rep
  local fn
  PKG_REP=""
  PKG_FILENAME=""
  for rep in $REPS; do
    fn=$(get_package_filename $rep $pkg)
    if [ -n "$fn" ]; then
      PKG_REP=$rep
      PKG_FILENAME=$fn
      break
    fi
  done
}