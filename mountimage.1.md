---
title: MOUNTIMAGE
section: 1
header: User Manual
footer: mountimage  2.00
date: February 21,2023
---
# NAME
Mountimage - Set up of Linux system images for offline changes.

# SYNOPSIS
**mountimage** [OPTIONS] IMAGE_FILE|DEVICE  
**mountimage** -u [MOUNT_OPTIONS|COMMON_OPTIONS] IMAGE_FILE|DEVICE  
**mountimage** -u [COMMON_OPTIONS] MOUNTPOINT

# DESCRIPTION
**mountimage** is used to mount/umount Linux system images with multiple partitions at a given mountpoint  according to

- A list of options 
- A profile
- A given **FSTAB** file.

These images are set up with multiple partitions: one is intended to be the root file system to be mounted as **/**, the other are intended to be mounted as sub directories (e.g. **/home** or **/boot**)

The images are stored at image files or mass storage devices.

Special hints:

- The program can be called multiple times to add additional sub mounts. At
  image files the same loop device is reused.
- Sub mount are ignored before root (/) is mounted.

Automounting of / (root):

The first valid mount can be setup by an option or be set automatically, if following conditions are met:

- GPT partitioning is used
- One has a partition type "SD_GPT_ROOT*" (the related UUID) set
- If more than one partition have been marked as ROOT partition, the first partition is used

Some information about partition types can be found at:
https://uapi-group.org/specifications/specs/discoverable_partitions_specification/



After mounting the system image it can be used for further activities like running devroots (e.g. **systemd-nspawn**).
After umounting the storage device / image file of the changed system can be processed like

- Plugging the storage device at a target
- Deploy a new image with changes

# OPTIONS

**Options: Umount options | Mount options | Common options**

**Umount options**:

    -u, --umount            Unmount all partitions at mount point and sub mounts.
                            This flag is handled before processing mount options.

**Mount options**:

    -p, --path=MDESCR       Description with information of partition and mountpoint
    -f, --fstab             Read entries from /etc/fstab of mounted device
                            / (root) must be mounted before
    -m, --mountpoint=DIR    Directory as mount point for / (root)

**Common options**:

    -r, --profile=PROFILE   Base name of profile, searched at PROFILEPATH.
                            Content is embedded in order of command options,
    -v, --verbose           Display additional infos to STDERR
    -l, --last              Print parameters of last mount options after processing
                            as preset for a new profile
    -h, --help              Print this help and exit
        --version           Print version of mountimage and exit

Possible entries for MDESCR:

PARTLABEL=<label\>:<mount point\>  
	label:          label of partition (only GPT, fallback to LABEL)  
	mount point: 	mount point at system image, e.g. / or /home or /bin, etc.

LABEL=<label\>:<mount point\>  
	label:          label of file system  
	mount point:    mount point at system image

UUID=<id\>:<mount point\>  
	id:             uuid of file system  
	mount point:    mount point at system image

PARTUUID=<id\>:<mount point\>  
	id:             uuid of partition> (only GPT)  
	mount point:    mount point at system image

PARTNR=<id\>:<mount point\>  
	id:             simply the partition number  
	mount point:    mount point at system image

A profile is stored at a file with same name at one of the locations at PROFILEPATH:

- /home/user/.config/mountimage
- /etc/mountimage

Each profile can set all mount options and another profiles, but each profile can only be loaded once.

Example of profile:

 -p PARTLABEL=system:/  
 -p PARTLABEL=general_storage:/home  
 -p PARTLABEL=boot:/boot  
 -p PARTLABEL=EFI:/boot/efi  
 -p PARTLABEL=firmware:/boot/firmware  

 
# EXAMPLES

mountimage -p PARTLABEL=system:/ -p PARTLABEL=general_storage:/home -p ... -m /mnt/rootfs /dev/sdx

mountimage -p PARTLABEL=system:/ -f -m /mnt/rootfs /dev/sdx

mountimage -u -p PARTLABEL=system:/ --fstab -m /mnt/rootfs system.img

mountimage -u /mnt/rootfs

mountimage -r apertis -m /mnt/rootfs /dev/sdx

mountimage -f -m /mnt/rootfs system.img # only if a partition is marked as ROOT partition)

# AUTHORS
Written by Thomas Mittelstädt

# SEE ALSO
       findmnt(8), mount(8), losetup(8), blkid(8)

# BUGS
Not known
