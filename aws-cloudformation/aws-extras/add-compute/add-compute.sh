#!/bin/bash
AVAILZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
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
CLUSTERNAME=`cat /opt/clusterware/etc/config.yml | grep name | awk 'NR==1{print $2}'`
#With AWS credentials - get ASG info
AWSDIR="/opt/clusterware/opt/aws/bin/aws"
STACKID=$($AWSDIR autoscaling describe-auto-scaling-groups --auto-scaling-group-names | grep AutoScalingGroupName | grep $CLUSTERNAME-ComputeGroup | awk '{print $4}')
CURRENTCAP=$($AWSDIR autoscaling describe-auto-scaling-groups --auto-scaling-group-names $STACKID | grep DesiredCapacity | awk '{print $4}')
DESIREDCAP=$(($CURRENTCAP+$COMPUTENUM))
#Add desired number of instances to existing group
$AWSDIR autoscaling update-auto-scaling-group --auto-scaling-group-name $STACKID --max-size $DESIREDCAP
$AWSDIR autoscaling set-desired-capacity --auto-scaling-group-name $STACKID --desired-capacity $DESIREDCAP
