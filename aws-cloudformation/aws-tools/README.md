#How to launch an Alces Compute environment using CLI
An Alces environment can be launched using your local workstation together with the AWS command-line tools. 

For information on installation of the AWS CLI tools, [visit the AWS howto](https://aws.amazon.com/cli/)

Once the AWS CLI tools have been installed - clone the `flight-appliance-support` repo to your workstation. *Note*: when configuring the AWS CLI tool, set the `output` method to `table`. This can be done in the `$HOME/.aws/config` file.  

#Environment deployment
To deploy cluster components, such as scheduler master nodes, scheduler compute hosts and more - a private cluster network must be deployed. The included template creates a complete private network to host your compute environment(s) in. 

The `settings` file is used to add important environment information for later use.  

Each component is deployed using AWS CloudFormation - this ensures simple deletion of all resources when you are finished.

##Network deployment
To deploy a cluster network, the following commands should be used in conjunction with the templates provided in the `flight-appliance-support/aws-cloudformation/aws-tools/templates` directory. The `$CLUSTERNAME` variable should be exported and added to the `settings` file for later use.  

Network creation:
```bash
CLUSTERNAME="alces-cluster"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-network \
	--template-body file://templates/network.json
echo "CLUSTERNAME=\"${CLUSTERNAME}\"" >> settings
```

Check the status of the network creation using: 
```bash
aws cloudformation describe-stack \
	--stack-name ${CLUSTERNAME}-network
```

Once the network stack has successfully created - add the network resource IDs to the `settings` file: 
```bash
for resource in VPCID GATEWAYID ROUTETABLEID SUBNETID NETWORKACL SECURITYGROUP; do
  id=$(aws cloudformation describe-stacks --stack-name ${CLUSTER_NAME}-network | grep $resource | awk '{print $4}');
  echo "${resource}=\"${id}\"" >> settings;
done
```

##Cluster login node
To deploy a cluster login node, which also hosts cluster scheduler services - the following commands should be used: 

Source the cluster settings file - this will load all of the required network IDs required to launch your environment: 
```bash
. settings
```

Create the login node stack. First set the instance type you wish to deploy, e.g. `c4.large` provides 2 cores/4GB memory. Also include the name of your AWS keypair - this is used to access the cluster login node:
```bash
LOGINTYPE="c4.large"
KEYPAIR="aws_ireland"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-login \
	--template-body file://templates/login.json \
	--parameters ParameterKey=LOGINTYPE,ParameterValue="$LOGINTYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR"
```

Once the login node stack has successfully created - you can obtain its public IP address - you can log in to the cluster login node using the previously provided AWS keypair together with the public IP as the `alces` user: 

```bash
LOGINIP=$(aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-login | \
	grep AccessIP | \
	awk '{print $4}')
echo "LOGINIP=\"${LOGINIP}\"" >> settings
ssh -i ~/.ssh/aws_ireland.pem alces@52.49.50.51
```
