#!/bin/bash -l
set -ex
awsbin="/opt/clusterware/opt/aws/bin/aws"
## Gather required information
awsregion=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
instanceid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
clustername=$(cat /opt/clusterware/etc/config.yml | grep "name:\ " | awk '{print $2}' | tr -d "'")
buildsubnet=$($awsbin ec2 --region $awsregion describe-subnets \
				--filters Name=tag:Name,Values=${clustername}-build | grep SubnetId | awk '{print $2}' | tr -d '",')
prvsubnet=$($awsbin ec2 --region $awsregion describe-subnets \
				--filters Name=tag:Name,Values=${clustername}-prv | grep SubnetId | awk '{print $2}' | tr -d "',")
nodetype=$(cat /opt/clusterware/etc/config.yml | grep "role:" | awk '{print $2}')

## Fetch from external source, preferably the master, which personality
## slot to use - e.g. `node4` with an IP tail of `.5`
## For example purposes, set example tails and hostnames
domain="vlj.alces.network"
logintail="10"
nodetail="11"
if [ $nodetype == "master" ];
then
  tail=$logintail
  profilename="login1"
else
  tail=$nodetail
  profilename="node1"
fi

## Add `build` and `prv` interfaces
buildintcreate=$($awsbin ec2 --output table --region $awsregion create-network-interface \
					--subnet-id $buildsubnet \
					--description "Build interface for $HOSTNAME" \
					--private-ip-address "10.75.10.$tail" | grep NetworkInterfaceId | awk '{print $4}')
prvintcreate=$($awsbin ec2 --output table --region $awsregion create-network-interface \
                    --subnet-id $prvsubnet \
                    --description "Prv interface for $HOSTNAME" \
                    --private-ip-address "10.75.20.$tail" | grep NetworkInterfaceId | awk '{print $4}')
buildintattach=$($awsbin ec2 --output table --region $awsregion attach-network-interface \
                    --network-interface-id ${buildintcreate} \
                    --instance-id $instanceid \
                    --device-index 1 | grep AttachmentId | awk '{print $4}')
prvintattach=$($awsbin ec2 --output table --region $awsregion attach-network-interface \
                    --network-interface-id ${prvintcreate} \
                    --instance-id $instanceid \
                    --device-index 2 | grep AttachmentId | awk '{print $4}')
$awsbin ec2 --region $awsregion modify-network-interface-attribute \
    --network-interface-id $buildintcreate \
    --attachment "AttachmentId=${buildintattach},DeleteOnTermination=true"
$awsbin ec2 --region $awsregion modify-network-interface-attribute \
    --network-interface-id $prvintcreate \
    --attachment "AttachmentId=${prvintattach},DeleteOnTermination=true"

## Set hostname
hostnamectl set-hostname ${profilename}.${domain}
hostnamectl set-hostname --transient ${profilename}.${domain}

## Populate hosts file
cat << EOF > /etc/hosts
127.0.0.1 localhost.localdomain localhost
127.0.0.1 localhost4.localdomain4 localhost4
::1 localhost.localdomain localhost
::1 localhost6.localdomain6 localhost6

10.75.10.${logintail} login1.vlj.alces.network login1
10.75.10.${nodetail} node1.vlj.alces.network node1
EOF

## Generate config files for additional interfaces
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE="eth1"
BOOTPROTO="none"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR="10.75.10.${tail}"
NETMASK="255.255.255.0"
EOF
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth2
DEVICE="eth2"
BOOTPROTO="none"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR="10.75.20.${tail}"
NETMASK="255.255.255.0"
EOF

## Bring each interface up
while [ ! "$(ip addr | grep "eth2")" ] || [ ! "$(ip addr | grep "eth1")" ]; 
do 
    sleep 1 
done
echo "Found build interface: eth1"
echo "Found prv interface: eth2"
ifup eth1 && ifup eth2
