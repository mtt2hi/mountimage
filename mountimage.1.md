---
title: MOUNTIMAGE.SH
section: 1
header: User Manual
footer: mountimage.sh  1.11
date: November 11,2022
---
# NAME
Mountimage.sh - Set up of Linux system images for offline changes. 

# SYNOPSIS
[MOUNTPOINT=<mount directory of root\> ][IMAGEDESCR=<list of passignment\> ] **mountimage.sh** imagename|device [profile] [mountpoint]
[MOUNTPOINT=<mount directory of root\> ] **mountimage.sh** -u [mountpoint]

# DESCRIPTION
**mountimage.sh** is used to mount/umount Linux system images with multiple partitions at a given mountpoint (look also to option **mountpoint** and environment variable **MOUNTPOINT**) according to a profile. 

These images are set up with multiple partitions: one is intended to be the root file system to be mounted as **/**, the other are intended to be mounted as sub directories (e.g. **/home** or **/boot**)

The images are stored at image files or mass storage devices.

The assignments partition=>mountpoint are provided by array environment variable **IMAGEDESCR** and stored at profiles. They are provided by different sources with following priorities.

- Option **mountdir** at command line
- Environment variables **IMAGEDESCR** and **MOUNTPOINT**
- User defined profile || last used setting at a **last** profile
- Default profile embedded at the script

After mounting the system image it can be used for further activities like running devroots (e.g. **systemd-nspawn**).
After umounting the storage device / image file of the changed system can be processed like

- Plugging the storage device at a target
- Deploy a new image with changes

The last settings are saved to be used at next time.

**mountimage.sh** alway does an implicit **umount** of given mountpoint before proceeding to mount an system image.

# OPTIONS
**imagename** 
: Path to system image file (.img) with partitions. Image file will be mounted with help of **losetup**

**device** 
: Name of storage device like **/dev/sdx**. Can be e.g. an SD card or SSD or USB stick device.

**-u**
: Umount the last mounted system image

**mountdir**
: Mountpoint for / of system image. Default at script is **/mnt/rootdir**

**profile**
: File with environment variables **IMAGEDSCR** and/or **MOUNTPOINT**, stored at **~/mountimage/**. A profile **last** can be used to setup own profiles.

**passignment**
: Assigns a partitition to a mount point and can be set in following formats:

- **PARTLABEL=<partlabel\>:<mountdir\>**
: **partlabel** defines partition label/name. If partition label can't be found, label is interpreted as **LABEL**, e.g. **PARTLABEL=system:/** or **PARTLABEL=boot:/boot**

- **LABEL=<label\>:<mountdir\>**
: **label** defines file system label/name, e.g. **LABEL=system:/** or **LABEL=boot:/boot**

- **UUID=<uuid\>:<mountdir\>**
: **uuid** defines file system uuid, e.g. **UUID=26bba953-3569-4e4a-9371-324256fdbb2d:/** 

- **PARTUUID=<partuuid\>:<mountdir\>**
: **partuuid** defines uuid of partition, e.g. **PARTUUID=4375eadd-a68f-41ea-8118-a2419206d164:/** 

- **PARTNR=<partnr\>:<mountdir\>**
: **partnr** defines partition number, e.g. **2:/** or **1:/boot**

- **FSTAB**
: **FSTAB** reads entries from **/etc/fstab** of mounted **/** volume, so an additional description for **/** must preceed. E.g. **IMAGEDESCR=(PARTLABEL=system:/ FSTAB)** 

# ENVIRONMENT

**IMAGEDSCR**
: Defines a list of assignments for partitions. The format is **IMAGEDESCR=(passignment(1) passignment(2) ...)**, e.g.

- **IMAGEDESCR=(PARTLABEL=system:/ PARTLABEL=home:/home)** at profiles
- **IMAGEDESCR="PARTLABEL=system:/ PARTLABEL=home:/home"** at environment variable 

**MOUNTPOINT**
: Defines mount point of root partition and basis for sub mounts. Same to parameter **mountdir**, but overrules this. E.g. **/mnt/rootfs**, **~/mymount**
 
# EXAMPLES
**mountimage.sh test.img**
: Mounts the Image **test.img** with default settings.

**mountimage.sh -u**
: Umount the last mount of **mountimage.sh** at **/mnt/rootfs**

**mountimage.sh test.img /mnt/rootfs2**
: Mounts the Image **test.img** at **/mnt/rootfs2** (instead of default **/mnt/rootfs**).

**mountimage.sh -u /mnt/rootfs2**
: Umount the last mount of **mountimage.sh** at **/mnt/rootfs2** 

**mountimage.sh /dev/sde**
: Mounts the device **/dev/sde** at **/mnt/rootfs** with default settings.

**mountimage.sh /dev/sde pi4**
: Loads the profile from **~/mountimage/pi4** and mounts the device **/dev/sde** at **/mnt/rootfs** (can be overruled by profile) with these settings.

**mountimage.sh /dev/sde pi4 ~/mymount**
: Loads the profile from **~/mountimage/pi4** and mounts the device **/dev/sde** at **~/mymount** with these settings.

**IMAGEDESCR="PARTLABEL=system:/ PARTLABEL=home:/home" mountimage.sh /dev/sde pi4**
: Loads the profile from **~/mountimage/pi4**, replaces the mount scheme with the one **IMAGEDESCR** at environment variable. Mounts the device **/dev/sde** at **/mnt/rootfs** (can be overruled by profile) with these settings.

# AUTHORS
Written by Thomas Mittelstädt

# SEE ALSO
       findmnt(8), mount(8), losetup(8), blkid(8)

# BUGS
Not known
