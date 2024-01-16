**mountimage** is used to mount partitioned images files and storage devices according to user profiles at a given mount point.
After mounting the device with root partition (**/**) and other partitions (e.g. **/home**, **/boot**, **/boot/firmware**, ...) the mount point
for the root partition can be used for further activities like running devroots (e.g. **systemd-nspawn**).
After umounting the storage device / image file the changed system can be started like usual.

**Mountimage.sh** uses tools from packages **mount** and **util-linux** to get/set the needed information. It can be called without sudo, but calls some other tools with **sudo**.

Please get more information a provided man page and help test, when starting **mountimage** without parameters.

**mountimage** script is already contributed to **Apertis** at https://gitlab.apertis.org/pkg/apertis-dev-tools/-/blob/apertis/v2024/tools/mountimage?ref_type=heads


