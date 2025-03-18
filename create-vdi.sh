#!/bin/sh
#

VDI=guix-dsk.vdi

# load the Network Block Device module
sudo modprobe nbd
# create a thin device
rm -f $VDI && qemu-img create -f vdi $VDI 100G
# ... mount it
sudo qemu-nbd -f vdi --connect=/dev/nbd0 $VDI
# ... partition it
sudo parted /dev/nbd0 mklabel msdos
sudo parted -a cylinder /dev/nbd0 mkpart primary ext4 1 93G
sudo parted -a cylinder /dev/nbd0 mkpart primary linux-swap 93G 100%
sudo parted /dev/nbd0 set 1 boot on
# ... create a suitable fs
sudo mkfs.ext4 /dev/nbd0p1
sudo mkswap /dev/nbd0p2
# ... have a look to the partions IDs
sudo blkid /dev/nbd0p1
sudo blkid /dev/nbd0p2
# ... mount the root fs
sudo mount /dev/nbd0p1 /mnt

