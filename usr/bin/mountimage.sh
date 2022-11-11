#!/bin/bash
# SPDX-License-Identifier: SPDX-License-Identifier: MPL-2.0
#
# Copyright (c) 2022 Thomas Mittelstaedt <thomas.mittelstaedt@de.bosch.com>

#set -x

exe() { echo "\$ $@" ; "$@" ; }

# mountimage <device|imagefile> [<mountpoint>] [<format>] 
# mountimage -u [<mountpoint>]

PROFILEBASE_D='~/mountimage.profiles'
eval PROFILEBASE=${PROFILEBASE_D}
MOUNTPOINT_DEFAULT=${MOUNTPOINT}

IMAGE_DEVICE=$1

if test "$IMAGE_DEVICE" != "-u" ; then
  FORMAT=${2:-\-}
  MOUNTPOINT=$3
else
  MOUNTPOINT=$2
fi



MOUNTPOINT_PAR=$MOUNTPOINT

IMAGEDESCR_DEFAULT=${IMAGEDESCR[@]}

function help () {
  echo "$(basename $0) <imagename| device> [<profile>|last] [<mount dir>]"
  echo "  mount an image file or device to with <profile> to <mount dir>"
  echo "$(basename $0) -u [<mount dir>]"
  echo "  unmount all mounted partitions of <mount dir>"
  echo "imagename: an image name like xyz.img with partitions"
  echo "device: a device of an image like /dev/sde"
  echo "mount dir: A mount directory for /, if not given, /mnt/rootfs is assumed" 
  echo "profile: a source script at ${PROFILEBASE_D}/<profile> with the content:"
  echo "  IMAGEDESCR=('<mountdescr 1>=<id 1>:<mount point 1>' \ "
  echo "              '<mountdescr 2>=<id 2>:<mount point 2>' \ "
  echo "             ..."
  echo "              '<partid x>:<mount point x>' \ "
  echo "              'FSTAB' \ "
  echo "             )"
  echo "  [MOUNTPOINT=<mount dir>]"
  cat << "EOF"
Possible entries for
<mountdescr> 	<id> 		
PARTLABEL      	<label of partion> (only GPT, fallback to LABEL)
LABEL			<label of file system>	
UUID			<uuid of file system>
PARTUUID		<uuid of partion> (only GPT)

Special entries for descriptions

<partid x> 	: Simple the partition number
FSTAB 		: Read further entries from /etc/fstab of mounted 
	
# Example 1 (Default):  
    IMAGEDESCR=('PARTLABEL=system:/' \
             'PARTLABEL=general_storage:/home' \
             'PARTLABEL=boot:/boot' \
             'PARTLABEL=EFI:/boot/efi' \
             'PARTLABEL=firmware:/boot/firmware' \
             'PARTLABEL=system2:/system2' \
             'PARTLABEL=nonred:/mnt/nonredundant' \
             'PARTLABEL=rescue:/rescue' \
             'PARTLABEL=data:/data' \
             )
# Example 2:  
    IMAGEDESCR=('2:/' \
             'LABEL=general_storage:/home' \
             'LABEL=boot:/boot' \
             )
# Example 3:  
    IMAGEDESCR=('PARTLABEL=system:/' \
             FSTAB \
             )
             
EOF
  echo "Also possible: IMAGEDESCR=\"PARTLABEL=<label>|<partnr>:<relative mount path> ...\" $(basename $0) ... , e.g."
  echo "IMAGEDESCR=\"PARTLABEL=system:/ PARTLABEL=home:/home\" $(basename $0) ..."
  echo ""
  echo "HINT: All non existing partitions are ignored, so the description is used as super set"
  echo "HINT 2:Last valid profile used is stored at ${PROFILEBASE_D}/last, if not valid, ${PROFILEBASE_D}/last is deleted"
}


function getdevicefromlabel() {

local devp=$1
local label=$2
local sdev
local sdev_label

  for sdev in ${devp}*
  do 
    sdev_label=$(sudo blkid -s LABEL -o value $sdev)
    if test "$sdev_label" = "$label"; then
      echo $sdev
      return
    fi
  done
}

function getdevicefrompartlabel() {

local devp=$1
local label=$2
local sdev
local sdev_label

  for sdev in ${devp}*
  do 
    sdev_label=$(sudo blkid -s PARTLABEL -o value $sdev)
    if test "$sdev_label" = "$label"; then
      echo $sdev
      return
    fi
  done
}

function getdevicefromuuid() {

local devp=$1
local label=$2
local sdev
local sdev_label

  for sdev in ${devp}*
  do 
    sdev_label=$(sudo blkid -s UUID -o value $sdev)
    if test "$sdev_label" = "$label"; then
      echo $sdev
      return
    fi
  done
}

function getdevicefrompartuuid() {

local devp=$1
local label=$2
local sdev
local sdev_label

  for sdev in ${devp}*
  do 
    sdev_label=$(sudo blkid -s PARTUUID -o value $sdev)
    if test "$sdev_label" = "$label"; then
      echo $sdev
      return
    fi
  done
}

function getdescr_from_fstab()
{
local fstab=$1
local disroot=$2

  while read -r MOUNTDESCR MOUNTPOINT FSTYPE OPTIONS S1 S2
  do
  #  PARTNR=$(echo $LINE|perl -ne 'print "$1\n" if /#\s+generated\s+by\s+\w+.sh\s+([^\s]+)\s+([^\s]+)/') 
    if ! echo $MOUNTDESCR | grep -q '^[[:blank:]]*#' && test -n "$OPTIONS"; then
      if test "$MOUNTPOINT" != "/"; then
        if  echo $OPTIONS | grep -q '\bbind\b'; then
          echo -n "BIND=$MOUNTDESCR:$MOUNTPOINT "
        else
          echo -n "$MOUNTDESCR:$MOUNTPOINT "
        fi
      fi  
    fi  
  done < "$fstab"
  echo
}

function mountdescrentry()
{
local entry=$1
local prefix=$2
local PARTNR LABELPATH IDTYPE IDVALUE MDEVICE 

  IFS=: read -r PARTNR LABELPATH <<< "$entry"
  IFS=\= read -r IDTYPE IDVALUE <<< "$PARTNR"
  if test "$IDTYPE" = "PARTLABEL"; then
    MDEVICE=$(getdevicefrompartlabel ${DEVICEP} ${IDVALUE})
    if [ -z "$MDEVICE" ]; then
      MDEVICE=$(getdevicefromlabel ${DEVICEP} ${IDVALUE})
      if [ -n "$MDEVICE" ]; then
        echo "Using LABEL instead of PARTLABEL for ${IDVALUE} at ${MDEVICE}"
      fi
    fi
  elif test "$IDTYPE" = "LABEL"; then
    MDEVICE=$(getdevicefromlabel ${DEVICEP} ${IDVALUE})
  elif test "$IDTYPE" = "UUID"; then
    MDEVICE=$(getdevicefromuuid ${DEVICEP} ${IDVALUE})
  elif test "$IDTYPE" = "PARTUUID"; then
    MDEVICE=$(getdevicefrompartuuid ${DEVICEP} ${IDVALUE})
  elif test "$IDTYPE" = "BIND"; then
    MBIND=${IDVALUE}
    MDEVICE=
  else
    MDEVICE="${DEVICEP}${PARTNR}"
  fi
  
  if [ -n "${MDEVICE}" ] || [ -n "${MBIND}" ]; then
    if [ ! -d "${MOUNTPOINT}$LABELPATH" ]; then
      exe sudo mkdir -p "${MOUNTPOINT}$LABELPATH"
    fi
    # if not already mounted
    if ! findmnt "${MOUNTPOINT}$LABELPATH" -o TARGET  -n > /dev/null; then
      echo -n "$prefix"
      if [ -n "${MDEVICE}" ] ; then
        exe sudo mount "${MDEVICE}" "${MOUNTPOINT}$LABELPATH"
      else
        exe sudo mount -o bind "${MOUNTPOINT}$MBIND" "${MOUNTPOINT}$LABELPATH"
      fi
    fi
  fi
}




MOUNTPOINT=${MOUNTPOINT:-/mnt/rootfs}

IMAGEDESCR=('PARTLABEL=system:/' \
           'PARTLABEL=general_storage:/home' \
           'PARTLABEL=boot:/boot' \
           'PARTLABEL=EFI:/boot/efi' \
           'PARTLABEL=firmware:/boot/firmware' \
           'PARTLABEL=system2:/system2' \
           'PARTLABEL=nonred:/mnt/nonredundant' \
           'PARTLABEL=rescue:/rescue' \
           'PARTLABEL=data:/data' \
           )

if test -n "$FORMAT" ; then
  profile="${PROFILEBASE}"/"$FORMAT"
  if test "$FORMAT" != "-"; then
    echo "Try to read profile from $profile"
    if [ -f "$profile" ]; then
      source "$profile"
    elif test "$FORMAT" != "last"; then 
      echo "Can't find profile at $profile"
      help
      exit 1
    fi
  fi
fi

if test -n "$MOUNTPOINT_PAR"; then
  MOUNTPOINT_DEFAULT=${MOUNTPOINT_PAR}
fi

MOUNTPOINT=${MOUNTPOINT_DEFAULT:-${MOUNTPOINT}}

if [ -n "${IMAGEDESCR_DEFAULT[@]}" ]; then
  echo "IMAGEDESCR is set by environment, ignoring value from profile"
  IMAGEDESCR=(${IMAGEDESCR_DEFAULT[@]})
fi 
if [ -z "$IMAGEDESCR" ] && test "$IMAGE_DEVICE" != "-u"; then
  echo "No valid array IMAGEDESCR given"
  help
  exit 0 
fi
if test "$IMAGEDESCR" = '-'; then
  IMAGEDESCR=
fi


#for str in ${IMAGEDESCR[@]}; do
#  echo "$str"
#done

#exit


if [ -z "$IMAGE_DEVICE" ]; then
  help
  exit 0
fi

#unmount resources first

SYSTEM_DEV=$(findmnt "$MOUNTPOINT" -o SOURCE  -n)
if [ -z "$SYSTEMD_DEV" ] && [ -f "$MOUNTPOINT"/env ]; then
  echo "Reading "$MOUNTPOINT"/env"
  . "$MOUNTPOINT"/env
  sudo rm "$MOUNTPOINT"/env
fi
if test -n "${SYSTEM_DEV}"; then
  for mountpoint in $(findmnt -R "${MOUNTPOINT}" -o TARGET  -n | tac | perl -ne 'print "$1\n" if /(\/.*)/') ;
  do 
    exe sudo umount "${mountpoint}"
    sync
  done
  DEVICE=$(echo ${SYSTEM_DEV} |perl -ne 'print "$1\n" if /(\/dev\/\w+?)p?\d+\Z/') 
  LOOP_DEV=$(echo ${SYSTEM_DEV} |perl -ne 'print "$1\n" if /(\/dev\/loop\d+).*\Z/')  
else
  LOOP_DEV=$DEVICE 
fi  
if test -n "${LOOP_DEV}" ; then
  IMAGE=$(losetup -a|perl -ne 'print "$1\n" if /''\((.+?)\)/')
  exe sudo losetup -d ${LOOP_DEV}
else
  IMAGE=
fi
if test "$IMAGE_DEVICE" != "-u" ; then
  #write last configuration
  [ -d "${PROFILEBASE}" ] || mkdir -p "${PROFILEBASE}"
  profile="${PROFILEBASE}"/last
  rm -f $profile
  echo "MOUNTPOINT=$MOUNTPOINT" >> $profile
  echo "IMAGEDESCR=(${IMAGEDESCR[@]})" >> $profile
  if [ -b "$IMAGE_DEVICE" ]; then
    DEVICE=$IMAGE_DEVICE
    DEVICEP=$DEVICE
    IMAGE=
    SYSTEM_DEV=
    #  partprobe has to be called 
    exe sudo partprobe ${DEVICE}
  else
    DEVICE=$(sudo losetup -f)
    DEVICEP="${DEVICE}p"
    exe sudo losetup -P ${DEVICE} "$IMAGE_DEVICE"
    IMAGE="$IMAGE_DEVICE"
    SYSTEM_DEV=
  fi
  if [ -z "$IMAGEDESCR" ]; then
    echo "DEVICE=$DEVICE" | sudo tee -a "$MOUNTPOINT"/env
  else
    SYSTEM_DEV=$(getdevicefromlabel ${DEVICEP} "system")
    if test -n "${DEVICEP}"; then
      for str in ${IMAGEDESCR[@]}; do
        if test "$str" != "FSTAB"; then
          mountdescrentry "$str"
        else
          IMAGEDESCR2=$(getdescr_from_fstab "$MOUNTPOINT"/etc/fstab)
          for str2 in ${IMAGEDESCR2[@]}; do
            mountdescrentry "$str2" "FSTAB:"
          done  
        fi
      done  
    fi
  fi
fi 

set +x

if test "$IMAGE_DEVICE" != "-u" ; then
  echo "IMAGEDESCR=${IMAGEDESCR[@]}"
  echo "FORMAT:$FORMAT"
fi
echo "IMAGE_DEVICE=$IMAGE_DEVICE"
echo "MOUNTPOINT:$MOUNTPOINT"
echo "DEVICE=$DEVICE"
echo "SYSTEM_DEV=$SYSTEM_DEV"
echo "IMAGE=$IMAGE"

