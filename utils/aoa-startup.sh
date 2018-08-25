
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


aoa() {

  if [ -n "$1" ]; then
    local cmd=$1
    shift
  else
    local cmd="help"
  fi

  case $cmd in

    "include_settings" )
      if [ -f "$AOA_DIR/etc/aoa-settings.sh" ]; then
        . "$AOA_DIR/etc/aoa-settings.sh"
      fi
    ;;

    * )
      # Run the functions script for commands not defined above
      sh "$AOA_DIR/utils/aoa-functions.sh" $cmd $*
      aoa include_settings
  esac
}

aoa include_settings
aoa wget_wrapper
aoa create_settings

