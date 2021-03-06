#!/bin/bash

# This script will start an example Alces Flight Compute HPC Cluster using Spot, Auto scaling groups and CloudWatch monitors
# The following template used is the 8-node template `2016.2` release. For additional templates, please visit
# the GitHub repository at the following URL: 
#   - https://github.com/alces-software/flight-aws-marketplace/tree/2016.2r1/flight-compute

# For detailed launch help - please visit the documentation:
#   - http://docs.alces-flight.com/en/latest/launch-aws/launching_on_aws.html

#Enter your desired cluster name
CLUSTERNAME="flight-cluster"

#Your amazon keypair name
KEYPAIR=""

#Choose a username for the administrator account
USERNAME="alces"

#Initial number of compute nodes
INITIALNODES=3

#Select the compute node instance type to use
# Available compute instance types include the following:
#     compute.small-c4.large, compute.medium-c4.2xlarge, compute.large-c4.4xlarge, compute.dedicated-c4.8xlarge 
#     balanced.small-m4.xlarge, balanced.medium-m4.2xlarge, balanced.large-m4.4xlarge, balanced.dedicated-m4.10xlarge
#     memory.small-r3.xlarge, memory.medium-r3.2xlarge, memory.large-r3.4xlarge, memory.dedicated-r3.8xlarge
COMPUTENODETYPE="compute.small-c4.large"

#Highest spot price you are prepared to pay - enter 0 for on-demand instances
COMPUTESPOTPRICE=0.5

#Select the login node machine type
# Available login node instance types include the following:
#     small-t2.large, medium-r3.2xlarge, large-c4.8xlarge
LOGINTYPE="small-t2.large"

#Choose the size in GB of storage to provision with the cluster login node 
#This defines the storage capacity available for applications and user home directories
LOGINSYSTEMDISKSIZE="100"

#Enter your IP address range for enhanced security, this allows SSH and VNC
#access from the entered range only
NETWORKCIDR="0.0.0.0/0"

#*optional* Enter an S3 bucket for usage with the Alces customise tool
#For more information on the Alces customisation tool, please visit the documentation:
#  - http://docs.alces-flight.com/en/latest/customisation/customisation.html
FLIGHTCUSTOMBUCKET=""

#*optional* Enter a custom profile for usage with the Alces customise tool
FLIGHTCUSTOMPROFILES=""

TEMPLATEDIR="/tmp/8-node.json"
curl -sL https://git.io/vrZpf > $TEMPLATEDIR

if [ -z "$KEYPAIR" ] ; then
  echo "Please set KEYPAIR" >&2
  exit 1
fi

aws cloudformation create-stack \
    --stack-name ${CLUSTERNAME} \
    --template-body file://${TEMPLATEDIR} \
    --capabilities CAPABILITY_IAM \
    --parameters \
                     ParameterKey=KeyPair,ParameterValue="$KEYPAIR" \
                     ParameterKey=Username,ParameterValue="$USERNAME" \
		             ParameterKey=InitialNodes,ParameterValue="$INITIALNODES" \
                     ParameterKey=ComputeType,ParameterValue="$COMPUTENODETYPE" \
                     ParameterKey=ComputeSpotPrice,ParameterValue="$COMPUTESPOTPRICE" \
                     ParameterKey=LoginType,ParameterValue="$LOGINTYPE" \
                     ParameterKey=LoginSystemDiskSize,ParameterValue="$LOGINSYSTEMDISKSIZE" \
                     ParameterKey=NetworkCIDR,ParameterValue="$NETWORKCIDR" \
                     ParameterKey=FlightCustomBucket,ParameterValue="$FLIGHTCUSTOMBUCKET" \
                     ParameterKey=FlightCustomProfiles,ParameterValue="$FLIGHTCUSTOMPROFILES"

echo "To view status of your stack, run 'aws cloudformation describe-stacks --stack-name ${CLUSTERNAME}'"
echo "To delete the stack, run 'aws cloudformation delete-stack --stack-name ${CLUSTERNAME}'"
