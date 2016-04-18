#!/bin/bash -l
if [ "$(id -u)" != "0" ]; then
   echo "Must be run as root" 1>&2
   exit 1
fi

echo "Please enter the private IP address of the Lustre MDS instance:"
read MDSIP

instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

case $instancetype in
  d2.xlarge)
    disknum=3
    disks="/dev/xvdba /dev/xvdbb /dev/xvdbc"
    ;;

  d2.2xlarge)
    disknum=6
    disks="/dev/xvdba /dev/xvdbb /dev/xvdbc /dev/xvdbd /dev/xvdbe /dev/xvdbf"
    ;;

  d2.4xlarge)
    disknum=12
    disks="/dev/xvdba /dev/xvdbb /dev/xvdbc /dev/xvdbd /dev/xvdbe /dev/xvdbf /dev/xvdbg /dev/xvdbh /dev/xvdbi /dev/xvdbj /dev/xvdbk /dev/xvdbl"
    ;;

  d2.8xlarge)
    disknum=24
    disks="/dev/xvdba /dev/xvdbb /dev/xvdbc /dev/xvdbd /dev/xvdbe /dev/xvdbf /dev/xvdbg /dev/xvdbh /dev/xvdbi /dev/xvdbj /dev/xvdbk /dev/xvdbl /dev/xvdbm /dev/xvdbn /dev/xvdbo /dev/xvdbp /dev/xvdbq /dev/xvdbr /dev/xvdbs /dev/xvdbt /dev/xvdbu /dev/xvdbv /dev/xvdbw /dev/xvdbx"
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
lvcreate --name ost0 -l $vgsize -i $disknum -I 256 $HOSTNAME
mkfs.lustre --index=0 --mgsnode=${MDSIP}1@tcp0 --fsname=scratch --ost --reformat /dev/${HOSTNAME}/ost0
mkdir -p /mnt/lustre/${HOSTNAME}/ost0
mount -t lustre /dev/${HOSTNAME}/ost0 /mnt/lustre/${HOSTNAME}/ost0
