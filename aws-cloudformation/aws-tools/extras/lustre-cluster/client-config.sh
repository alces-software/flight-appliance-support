#!/bin/bash -l
clustername=$(sudo cat /opt/clusterware/etc/config.yml | grep name | awk '{print $2}')

if [ "$HOSTNAME" -ne login1 ];
  echo "Please run from the cluster login node"
  exit 1
fi

echo "Please enter the private IP address of the Lustre MDS instance:"
read MDSIP

cat << EOF > $HOME/lustre.repo
[lustre-client]
name=Lustre client for el7
baseurl=https://s3-eu-west-1.amazonaws.com/repos.alces-software.com/lustre/intel/2.4.1.1/client/el7/
enabled=1
priority=2
gpgcheck=0
skip_if_unavailable=1
EOF

pdsh -g cluster 'sudo cp $HOME/lustre.repo /etc/yum.repos.d/lustre.repo'
pdsh -g cluster 'sudo yum -y install lustre-client'
pdsh -g cluster 'sudo mkdir -p /mnt/lustre'
pdsh -g cluster 'sudo mount -t lustre ${MDSIP}@tcp0:/${clustername} /mnt/lustre'
