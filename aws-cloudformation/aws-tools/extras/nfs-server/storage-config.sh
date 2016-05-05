#!/bin/bash -l
instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

case $instancetype in
  d2.xlarge)
    disknum=3
    sudo pvcreate /dev/xvdba /dev/xvdbb /dev/xvdbc
    sudo vgcreate data /dev/xvdba /dev/xvdbb /dev/xvdbc
    vgsize=$(sudo vgdisplay | grep "Total PE" | awk '{print $3}')
    sudo lvcreate --name storage1 -l $vgsize -i $disknum -I 256 data
    mountpoint="/dev/mapper/data-storage1"
    ;;

  d2.2xlarge)
    disknum=6
    sudo pvcreate /dev/xvdba /dev/xvdbb /dev/xvdbc \
                  /dev/xvdbd /dev/xvdbe /dev/xvdbf
    sudo vgcreate data /dev/xvdba /dev/xvdbb /dev/xvdbc \
                       /dev/xvdbd /dev/xvdbe /dev/xvdbf
    vgsize=$(sudo vgdisplay | grep "Total PE" | awk '{print $3}')
    sudo lvcreate --name storage1 -l $vgsize -i $disknum -I 256 data
    mountpoint="/dev/mapper/data-storage1"
    ;;

  d2.8xlarge)
    disknum=24
    sudo pvcreate /dev/xvdba /dev/xvdbb /dev/xvdbc /dev/xvdbd \
             /dev/xvdbe /dev/xvdbf /dev/xvdbg \
             /dev/xvdbh /dev/xvdbi /dev/xvdbj \
             /dev/xvdbk /dev/xvdbl /dev/xvdbm \
             /dev/xvdbn /dev/xvdbo /dev/xvdbp \
             /dev/xvdbq /dev/xvdbr /dev/xvdbs \
             /dev/xvdbt /dev/xvdbu /dev/xvdbv \
             /dev/xvdbw /dev/xvdbx
    sudo vgcreate data /dev/xvdba /dev/xvdbb /dev/xvdbc /dev/xvdbd \
                  /dev/xvdbe /dev/xvdbf /dev/xvdbg \
                  /dev/xvdbh /dev/xvdbi /dev/xvdbj \
                  /dev/xvdbk /dev/xvdbl /dev/xvdbm \
                  /dev/xvdbn /dev/xvdbo /dev/xvdbp \
                  /dev/xvdbq /dev/xvdbr /dev/xvdbs \
                  /dev/xvdbt /dev/xvdbu /dev/xvdbv \
                  /dev/xvdbw /dev/xvdbx
    vgsize=$(sudo vgdisplay | grep "Total PE" | awk '{print $3}')
    sudo lvcreate --name storage1 -l $vgsize -i $disknum -I 256 data
    mountpoint="/dev/mapper/data-storage1"
    ;;

    m4.xlarge|m4.2xlarge|m4.4xlarge|m4.10xlarge)
      mountpoint="/dev/xvdb"
    ;;

    *)
      echo "Invalid instance type"
      exit 1
esac

sudo -s <<EOF
  mkfs.xfs ${mountpoint}
  mkdir /mnt/data
  mount ${mountpoint} /mnt/data
  chmod 0777 /mnt/data
  echo "/mnt/data 10.75.0.0/16(rw,no_root_squash,no_subtree_check,sync)" >> /etc/exports
  sed -i '/RPCNFSDCOUNT/c\RPCNFSDCOUNT=320' /etc/sysconfig/nfs
  systemctl restart rpcbind
  systemctl restart nfs-server
  exportfs -a
EOF
ssh login1 'pdsh -g cluster sudo mkdir /mnt/data'
ssh login1 'pdsh -g cluster sudo mount -t nfs storage1:/mnt/data /mnt/data -o wsize=65536,rsize=65536'
