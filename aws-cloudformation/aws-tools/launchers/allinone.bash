#!/bin/bash

#This script will start an example Alces Flight Compute HPC Cluster using Spot, Auto scaling groups and CloudWatch monitors

#The name of the cluster
CLUSTERNAME='mycluster'

#Your amazon keypair name
KEYPAIR=""

#Initial number of compute nodes
NODES=3

#Compute node machine type, choose from small or large
NODETYPE=small

#Highest spot price you are prepared to pay
SPOTPRICE=0.5


BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if [ -z "$KEYPAIR" ] ; then
  echo "Please set KEYPAIR" >&2
  exit 1
fi

aws cloudformation create-stack \
    --stack-name ${CLUSTERNAME} \
    --template-body file://$BASEDIR/../templates/all-in-one/hpc-cluster.json \
    --parameters \
                     ParameterKey=KeyPair,ParameterValue="$KEYPAIR" \
		     ParameterKey=ComputeNumber,ParameterValue="$NODES" \
                     ParameterKey=InstanceFlavour,ParameterValue="$NODETYPE" \
                     ParameterKey=SpotPrice,ParameterValue="$SPOTPRICE"

echo "To view status of your stack, run 'aws cloudformation describe-stacks --stack-name $CLUSTERNAME'"
echo "To delete the stack, run 'aws cloudformation delete-stack --stack-name $CLUSTERNAME'"
