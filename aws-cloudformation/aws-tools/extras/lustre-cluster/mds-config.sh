#!/bin/bash -l
instancetype=$(curl -ssL http://169.254.169.254/latest/meta-data/instance-type)

if [ "$(id -u)" != "0" ]; then
   echo "Must be run as root" 1>&2
   exit 1
fi

case $instancetype in
  i2.xlarge)
    disknum=1
    disks="/dev/xvdba"
    ;;

  i2.2xlarge)
    disknum=2
    disks="/dev/xvdba /dev/xvdbb"
    ;;

  *)
    echo "Invalid instance type"
    exit 1
    ;;

esac

modprobe -v lustre
pvcreate $disks
vgcreate $HOSTNAME $disks
vgsize=$(vgdisplay | grep "Total PE" | awk '{print $3}')
lvcreate --name mdt -l $vgsize -i $disknum -I 256 $HOSTNAME
mkfs.lustre --index=0 --mgs --mdt --fsname=scratch --reformat /dev/${HOSTNAME}/mdt
mkdir -p /mnt/lustre/mdt
mount -t lustre /dev/${HOSTNAME}/mdt /mnt/lustre/mdt
