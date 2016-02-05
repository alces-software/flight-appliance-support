#!/bin/bash
#Fetch required AWS info to launch a new instance
MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
VPCID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-id)
SUBNETID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/subnet-id)
SECGID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/security-group-ids)
AMIID=$(curl -s http://169.254.169.254/latest/meta-data/ami-id)
INSTANCETYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
AVAILZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
CLUSTERMASTER=$(ifconfig eth0 | grep inet | awk 'NR==1{print $2}')
STACKID=
#Get AWS keys
if ! [ -f $HOME/.aws/credentials ]
then
echo "Enter your AWS Access Key ID"
read AWSACCESS
echo "Enter your AWS Secret Access Key"
read AWSSECRET
mkdir $HOME/.aws
cat << EOF > $HOME/.aws/credentials
[default]
aws_access_key_id = $AWSACCESS
aws_secret_access_key = $AWSSECRET
EOF
#Create AWS configs
cat << EOF > $HOME/.aws/config
[default]
output = table
region = $AVAILZONE
EOF
fi
echo "Number of compute nodes to deploy"
read COMPUTENUM
#Fetch ClusterWare info
UUID=$(cat /opt/clusterware/etc/config.yml | grep uuid | awk '{print $2}' | tr -d "'")
TOKEN=$(cat /opt/clusterware/etc/config.yml | grep token | awk '{print $2}' | tr -d "'")
CLUSTERNAME=`cat /opt/clusterware/etc/config.yml | grep name | awk 'NR==1{print $2}'`
#With AWS credentials - get ASG info
STACKID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names | grep AutoScalingGroupName | grep $CLUSTERNAME-ComputeGroup | awk '{print $4}')
CURRENTCAP=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $STACKID | grep DesiredCapacity | awk '{print $4}')
DESIREDCAP=$(($CURRENTCAP+$COMPUTENUM))
#Add desired number of instances to existing group
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $STACKID --max-size $DESIREDCAP
aws autoscaling set-desired-capacity --auto-scaling-group-name $STACKID --desired-capacity $DESIREDCAP