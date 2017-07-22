
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

AOA_SETUP=$1
shift
CMD=$1
shift

# Include the functions from the setup script
. $AOA_SETUP

# Include busybox functions
. $(aoa get_script busybox)

# Include package manager functions
. $(aoa get_script package-manager)

# Print string on stderr
error()
{
  echo "$1" 1>&2
}

# Print string on stderr
msg()
{
  echo "$1" 1>&2
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

second_stage_check()
{
  busybox_check
}

$CMD $*

