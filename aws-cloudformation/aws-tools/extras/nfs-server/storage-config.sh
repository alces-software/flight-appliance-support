#!/bin/bash -l
disk=$(sudo fdisk -l | grep xvdb)
if [ -n "$disk" ]; then
sudo -s <<EOF
  mkfs.xfs /dev/xvdb
  mkdir /mnt/data
  mount /dev/xvdb /mnt/data
  chmod 0777 /mnt/data
  echo "/mnt/data 10.75.0.0/16(rw,no_root_squash,no_subtree_check,sync)" >> /etc/exports
  sed -i '/RPCNFSDCOUNT/c\RPCNFSDCOUNT=320' /etc/sysconfig/nfs
  systemctl restart rpcbind
  systemctl restart nfs-server
  exportfs -a
EOF
ssh login1 'pdsh -g cluster sudo mkdir /mnt/data'
ssh login1 'pdsh -g cluster sudo mount storage1:/mnt/data /mnt/data -t nfs -o wsize=65536,rsize=65536'
else
  echo "Disk not present - please check the volume has been mounted"
  exit 1
fi
