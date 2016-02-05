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
#Define CFN template
curl -sS https://gist.githubusercontent.com/vlj91/bf35c7cae745a49a3066/raw/dcc3dc6bcfdc4325f82e5315ccb91959bdd18c0f/nodes.json > /tmp/$CLUSTERNAME-nodes.json
sed -e "s,%AMIID%,$AMIID,g" \
    -e "s,%INSTANCETYPE%,$INSTANCETYPE,g" \
    -e "s,%SECGID%,$SECGID,g" \
    -e "s,%UUID%,$UUID,g" \
    -e "s,%TOKEN%,$TOKEN,g" \
    -e "s,%CLUSTERNAME%,$CLUSTERNAME,g" \
    -e "s,%MASTERNODE%,$CLUSTERMASTER,g" \
    -e "s,%COMPUTENUM%,$COMPUTENUM,g" \
    -e "s,%VPCID%,$VPCID,g" \
    -e "s,%SUBNETID%,$SUBNETID,g" \
    -i /tmp/$CLUSTERNAME-nodes.json
aws cloudformation create-stack --stack-name $CLUSTERNAME-compute --template-body file:///tmp/$CLUSTERNAME-nodes.json
