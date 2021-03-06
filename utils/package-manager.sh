
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
PKG_DIR="$CACHE_DIR/packages"
URL_BASE="http://mirror.archlinuxarm.org/aarch64"

install() {
  patchelf_check
  local pkg=$1
  local fl=$AOA_DIR/pkginfo/$pkg.files
  if [ -f "$fl" ]; then
    echo "Already installed: $pkg" >&2
  else
    install_deps "$pkg"
  fi
}

update() {
  get_package_lists
}

install_deps() {
  local pkg="$1"
  case "$pkg" in

    "gcc" )
      install libmpc
      install mpfr
      install gmp
      install zlib
      install linux-api-headers
      install binutils
      install_pkg gcc
      postinst_gcc
    ;;

    "make" )
      install guile
      install gc
      install libffi
      install libunistring
      install libtool
      install libatomic_ops
      install_pkg make
      postinst_make
    ;;

    * )
      install_pkg "$pkg"

  esac
}

install_pkg() {
  local pkg="$1"
  pkg_download_expand "$pkg"
  pkg_ammend_so_path "$pkg"
  pkg_ammend_interp "$pkg"
}

patchelf_check() {
  patchelf --version > /dev/null 2>&1 || patchelf_install
}

patchelf_install() {
  local PKGS=$(echo -e "filesystem\nglibc\ngcc-libs\npatchelf")
  local pkg
  for pkg in $PKGS; do
    pkg_download_expand $pkg
  done
  local ld=$(find $AOA_DIR/lib/ld-linux*)
  cp "$AOA_DIR/usr/bin/patchelf" "$AOA_DIR/usr/bin/patchelf.orig"
  "$ld" "$AOA_DIR/usr/bin/patchelf.orig" --set-interpreter "$ld" "$AOA_DIR/usr/bin/patchelf"
  patchelf --version > /dev/null 2>&1 
  if [ $? -eq 0 ]; then
    rm "$AOA_DIR/usr/bin/patchelf.orig"
    for pkg in $PKGS; do
      #[ "$pkg" != "patchelf" ] && pkg_ammend_interp $pkg
      pkg_ammend_so_path "$pkg"
    done
  else
    echo "Could not successfully install patchelf." >&2
  fi    
}

pkg_download_expand() {
  local pkg="$1"
  local fl=$AOA_DIR/pkginfo/$pkg.files
  mkdir -p $AOA_DIR/pkginfo
  if [ -f "$fl" ]; then
    echo "Already installed: $pkg" >&2
  else
    local fn=$(pkg_download "$pkg")
    if [ -z "$fn" ]; then
      echo "Could not find '$pkg', try running 'aoa update' and check package name." >&2
    else
      # The actual package expansion
      local pdir=$PWD
      echo "Expanding package: $fn" >&2
      cd $AOA_DIR
      xzcat $fn | tar -xv > "$fl"
      mv .PKGINFO "pkginfo/$pkg.PKGINFO"
      cd $pdir
    fi
  fi
}

pkg_download()
{
  local pkg="$1"
  get_package_rep_and_filename "$pkg"
  local dst_dir="$CACHE_DIR/packages/$PKG_REP"
  local url="$URL_BASE/$PKG_REP/$PKG_FILENAME"
  local fn="$PKG_FILENAME"

  if [ -n "$fn" ]; then

    # Some Arch packages have + or : in them which are url encoded, decode them for filename.
    local fn1=$(echo "$fn" | sed "s/%2b/+/g" | sed "s/%3a/:/g" 2> /dev/null)
    [ -n "$fn1" ] && fn="$fn1"

    # If not already downloaded to cache then download
    if [ ! -e "$dst_dir/$fn" ]; then
      wget --no-clobber --no-check-certificate --directory-prefix=$dst_dir $url
    fi

    # If downloaded then return the path
    if [ -e "$dst_dir/$fn" ]; then
      echo "$dst_dir/$fn"
    fi

  fi
}

pkg_ammend_so_path() {
  local pkg=$1
  local prev_dir="$PWD"
  cd "$AOA_DIR"
  for fn in $(cat $AOA_DIR/pkginfo/$pkg.files); do
    if [ -f "$fn" ]; then
      # Check that file is not a symbolic link
      if [ ! -L "$fn" ]; then
        # Check filename is *.so
        echo "$fn" | grep -q "[.]so$"
        if [ $? -eq 0 ]; then
          # Check file is not ELF
          head -c4 "$fn" | grep -q "ELF"
          if [ $? -ne 0 ]; then
            mv "$fn" "$fn.orig"
            cat "$fn.orig" | sed "s= /usr/lib/= $AOA_DIR/usr/lib/=g" > "$fn"
          fi
        fi
      fi
    fi
  done
  cd "$prev_dir"
}

pkg_ammend_interp() {
  local pkg=$1
  local pdir="$PWD"
  cd "$AOA_DIR"
  local ld="$AOA_DIR/$(find lib/ld-linux*)"
  for fn in $(cat pkginfo/$pkg.files); do
    if [ -x "$fn" ]; then
      if [ -f "$fn" ]; then
        patchelf --set-interpreter "$ld" "$fn" 2> /dev/null
      fi
    fi
  done
  cd "$pdir"
}

get_db() {
  local db=$(download http://mirror.archlinuxarm.org/aarch64/$1/$1.db packages)
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
  download http://mirror.archlinuxarm.org/aarch64/core/ packages/core
}

get_hrefs() {
  local url=$1
  echo $url | busybox grep '://' || url=http://mirror.archlinuxarm.org/$url
  wget $url -O - | sed -n "s|.*href=\"||p" | sed "s|\".*||" | sed "s|^./||" | sed "s|%3A|:|"
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

test_gcc() {
  local pdir="$PWD"
  mkdir -p "$AOA_DIR/tests"
  cd "$AOA_DIR/tests"
  cat << EOF > test.c
#include <stdio.h>

int main( int argc, char *arg[] )
{
  printf("Compiled with GCC in ArchOnAndroid!\n");
  return 0;
}
EOF

  echo "Compiling test.c" >&2
  gcc test.c
  ./a.out
  cd "$pdir"
}

postinst_gcc() {
  local dst=$(find "$AOA_DIR/usr/lib/gcc/" | sed -n 's=/lto-wrapper==p')/specs
  gcc -dumpspecs | sed "s=/lib=$AOA_DIR/lib=g" > "$dst"
  local vers=$(find "$AOA_DIR/usr/include/c++/" | sed -n "s|vector$||p" | sed "s|.*/c++/||" | sed "s|/.*||" | head -n1)
  export C_INCLUDE_PATH="$AOA_DIR/usr/include"
  add_setting C_INCLUDE_PATH "$C_INCLUDE_PATH"
  add_setting CPLUS_INCLUDE_PATH "$AOA_DIR/usr/include/c++/$vers:$AOA_DIR/usr/include"
  test_gcc
}

postinst_make() {
  # Make a wrapper for make to set the SHELL variable.
  local fn="$AOA_DIR/usr/bin/make"
  [ ! -f "$fn-bin" ] && mv "$fn" "$fn-bin"
  cat << EOF > "$fn"
#!$(which sh)

make-bin SHELL=$(which sh) \$@
EOF
  chmod +x "$fn"
}

set_shebang()
{
  local fn="$1"
  local sb="#!$(which sh)"
  local sbf=$(head -n1 "$fn")
  if [ "$sbf" != "$sb" ];then
    sed -i "1s|#!.*|$sb|" "$fn"
  fi
}
