#!/bin/bash

#set -x

exe() { echo "\$ $@" ; "$@" ; }

# mountimage <device|imagefile> [<mountpoint>] [<format>] 
# mountimage -u [<mountpoint>]


IMAGE_DEVICE=$1

FORMAT=${2:-last}

MOUNTPOINT=$3

function help () {
  echo "$(basename $0) <imagename| device> [<profile>] [<mount dir>]"
  echo "  mount an image file or device to with <profile> to <mount dir>"
  echo "$(basename $0) -u [<mount dir>]"
  echo "  unmount all mounted partitions of <mount dir>"
  echo "imagename: an image name like xyz.img with partitions"
  echo "device: a device of an image like /dev/sde"
  echo "mount dir: A mount directory for /, if not given, /mnt/rootfs is assumed" 
  echo "profile: a source script at ~/mountimage.profiles/<profile> with the content:"
  echo "  IMAGEDESCR=('LABEL=<label>|<partnr>:<relative mount path>' \ "
  echo "              'LABEL=<label>|<partnr>:<relative mount path>' \ "
  echo "             ..."
  echo "             )"
  echo "  [MOUNTPOINT=<mount dir>]"
  cat << "EOF"
# Example 1:  
    IMAGEDESCR=('LABEL=system:/' \
             'LABEL=general_storage:/home' \
             'LABEL=boot:/boot' \
             'LABEL=EFI:/boot/efi' \
             'LABEL=firmware:/boot/firmware' \
             'LABEL=system2:/system2' \
             'LABEL=nonred:/mnt/nonredundant' \
             'LABEL=rescue:/rescue' \
             'LABEL=data:/data' \
             )
# Example 2:  
    IMAGEDESCR=('2:/' \
             '3:/home' \
             '1:/boot' \
             )
EOF
  echo "  HINT: All non existing partitions are ignored, so the description is used as super set"
  echo "  HINT 2:Last valid profile used is stored at ~/mountimage.profiles/last, if not valid, ~/mountimage.profiles/last is deleted"
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



if [ -d "$FORMAT" ]; then
  MOUNTPOINT=$2
  FORMAT=$3
fi

MOUNTPOINT=${MOUNTPOINT:-/mnt/rootfs}

IMAGEDESCR=('LABEL=system:/' \
           'LABEL=general_storage:/home' \
           'LABEL=boot:/boot' \
           'LABEL=EFI:/boot/efi' \
           'LABEL=firmware:/boot/firmware' \
           'LABEL=system2:/system2' \
           'LABEL=nonred:/mnt/nonredundant' \
           'LABEL=rescue:/rescue' \
           'LABEL=data:/data' \
           )
if test -n "$FORMAT" ; then
  profile=~/mountimage.profiles/"$FORMAT"
  if test "$FORMAT" != "last"; then
    rm -f ~/mountimage.profiles/last
  fi
  echo "Try to read profile from $profile"
  if [ -f "$profile" ]; then
    source "$profile"
    if test "$FORMAT" != "last"; then
       cp ~/mountimage.profiles/"$FORMAT" ~/mountimage.profiles/last
    fi
  elif test "$FORMAT" != "last"; then 
    echo "Can't find profile at $profile"
    help
    exit 1
  fi
  if [ -z "$IMAGEDESCR" ]; then
    echo "No valid array IMAGEDESCR given"
    help
    exit 0 
  fi
else  
  rm -f ~/mountimage.profiles/last
fi


if [ -z "$IMAGE_DEVICE" ]; then
  help
  exit 0
fi

#unmount resources first

SYSTEM_DEV=$(findmnt "$MOUNTPOINT" -o SOURCE  -n)
if test -n "${SYSTEM_DEV}"; then
  for dev in $(findmnt -R "$MOUNTPOINT" -o SOURCE  -n | tac) ;do exe sudo umount ${dev} ;done
  DEVICE=$(echo ${SYSTEM_DEV} |perl -ne 'print "$1\n" if /(\/dev\/\w+?)p?\d+\Z/')  
  LOOP_DEV=$(echo ${SYSTEM_DEV} |perl -ne 'print "$1\n" if /(\/dev\/loop\d+).*\Z/')  
  if test -n "${LOOP_DEV}" ; then
    IMAGE=$(losetup -a|perl -ne 'print "$1\n" if /''\((.+?)\)/')
    exe sudo losetup -d ${LOOP_DEV}
  else
    IMAGE=
  fi
fi
if test "$IMAGE_DEVICE" != "-u" ; then
  if [ -b "$IMAGE_DEVICE" ]; then
    DEVICE=$IMAGE_DEVICE
    DEVICEP=$DEVICE
    IMAGE=
    SYSTEM_DEV=
  else
    DEVICE=$(sudo losetup -f)
    DEVICEP="${DEVICE}p"
    exe sudo losetup -P ${DEVICE} "$IMAGE_DEVICE"
    IMAGE="$IMAGE_DEVICE"
    SYSTEM_DEV=
  fi
  SYSTEM_DEV=$(getdevicefromlabel ${DEVICEP} "system")
  if test -n "${DEVICEP}"; then
    for str in ${IMAGEDESCR[@]}; do
      IFS=: read -r PARTNR LABELPATH <<< "$str"
      IFS=\= read -r IDTYPE IDVALUE <<< "$PARTNR"
      if test "$IDTYPE" = "LABEL"; then
        MDEVICE=$(getdevicefromlabel ${DEVICEP} ${IDVALUE})
      else
        MDEVICE="${DEVICEP}${PARTNR}"
      fi
      if [ -n "${MDEVICE}" ]; then
        exe sudo mount "${MDEVICE}" "${MOUNTPOINT}$LABELPATH"
      fi
    done  
  fi
fi 

set +x

echo "IMAGE_DEVICE=$IMAGE_DEVICE"
echo "FORMAT:$FORMAT"
echo "MOUNTPOINT:$MOUNTPOINT"
echo "DEVICE=$DEVICE"
echo "SYSTEM_DEV=$SYSTEM_DEV"
echo "IMAGE=$IMAGE"

