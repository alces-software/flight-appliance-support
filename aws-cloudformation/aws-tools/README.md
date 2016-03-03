#How to launch an Alces Compute environment using CLI
An Alces environment can be launched using your local workstation together with the AWS command-line tools. 

For information on installation of the AWS CLI tools, [visit the AWS howto](https://aws.amazon.com/cli/)

Once the AWS CLI tools have been installed - clone the `flight-appliance-support` repo to your workstation. *Note*: when configuring the AWS CLI tool, set the `output` method to `table`. This can be done in the `$HOME/.aws/config` file.  

Your AWS configuration file must contain the two following settings to correctly follow the following steps - make sure you add the following values to the configuration file. This is usually located on UNIX machines at `$HOME/.aws/config`: 

```
[default]
output = table
region = eu-west-1
```

#Environment deployment
To deploy cluster components, such as scheduler master nodes, scheduler compute hosts and more - a private cluster network must be deployed. The included template creates a complete private network to host your compute environment(s) in. 

The `settings` file is used to add important environment information for later use. Before deploying - add the name of your AWS keypair as listed in your AWS account to the `settings` file, for example: 

To begin - copy the `settings.example` file to `settings` to work with the remainder of the walkthrough: 

```bash
cp settings.example settings
```

```bash
KEYPAIR="mykeypair"
``` 

Next - include your desired cluster name in the `settings` file, for example: 

```bash
CLUSTERNAME="alces-cluster"
```

Each component is deployed using AWS CloudFormation - this ensures simple deletion of all resources when you are finished.

##Network deployment
To deploy a cluster network, the following commands should be used in conjunction with the templates provided in the `flight-appliance-support/aws-cloudformation/aws-tools/templates` directory. The `$CLUSTERNAME` variable should be exported and added to the `settings` file for later use.  

Before running the following commands - source the `settings` file: 

```bash
. settings
```

Network creation:
```bash
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-network \
	--template-body file://templates/network.json
```

Check the status of the network creation using: 
```bash
aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-network
```

Once the network stack has successfully created - add the network resource IDs to the `settings` file: 
```bash
for resource in VPCID GATEWAYID ROUTETABLEID SUBNETID NETWORKACL SECURITYGROUP; do
  id=$(aws cloudformation describe-stacks --stack-name ${CLUSTERNAME}-network | grep $resource | awk '{print $4}');
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
NODENAME="login1"
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
                     ParameterKey=LOGINAMI,ParameterValue="$LOGINAMI" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=NODENAME,ParameterValue="$NODENAME" 
```

Once the login node stack has successfully created - you can obtain its public IP address - you can log in to the cluster login node using the previously provided AWS keypair together with the public IP as the `alces` user: 

```bash
LOGINPUBIP=$(aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-login | \
	grep AccessIP | \
	awk '{print $4}')
echo "LOGINPUBIP=\"${LOGINPUBIP}\"" >> settings
```

Now - SSH to the login node public IP as the `alces` user, together with the previously provided AWS key.

The login nodes internal IP address also needs to be gathered in order to correctly create and configure cluster compute nodes - gather the internal IP and add it to the `settings` file: 

```bash
LOGINIP=$(aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-login | \
	grep InternalIP | \
        awk '{print $4}')
echo "LOGINIP=\"${LOGINIP}\"" >> settings
```

##Launching compute nodes
To deploy cluster compute nodes, used for scheduling your jobs and running applications on - the following commands should be used.

###Single compute node
To launch a single compute node, run the following commands. Make sure you have sourced your `settings` file before running the following commands.

```bash
. settings
```

Create a single compute node using the following command - a compute node instance type should also be chosen, such as `c4.large`.

```bash
COMPUTETYPE="c4.large"
NODENAME="node01"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-${NODENAME} \
	--template-body file://templates/1-node.json \
	--parameters ParameterKey=COMPUTETYPE,ParameterValue="$COMPUTETYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=NODENAME,ParameterValue="$NODENAME" \
                     ParameterKey=COMPUTEAMI,ParameterValue="$COMPUTEAMI" \
                     ParameterKey=LOGINIP,ParameterValue="$LOGINIP" 
```

Once stack creation is successful - your new node `node01` will join the environment, registering itself as ready for compute jobs. 

##Multiple compute nodes
To deploy multiple compute nodes to your environment, run the following commands. Make sure you source your `settings` file before running the following commands. 

```bash
. settings
```

Create multiple compute nodes, up to the limit of your AWS account (typically 10). A compute node instance type should also be chosen, such as `c4.large`. 

```bash
COMPUTETYPE="c4.large"
NODENUMBER="5"
aws cloudformation create-stack \
        --stack-name ${CLUSTERNAME}-compute-$$ \
        --template-body file://templates/multiple-nodes.json \
        --parameters ParameterKey=COMPUTETYPE,ParameterValue="$COMPUTETYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=NODENUMBER,ParameterValue="$NODENUMBER" \
                     ParameterKey=COMPUTEAMI,ParameterValue="$COMPUTEAMI" \
                     ParameterKey=LOGINIP,ParameterValue="$LOGINIP"
```

#Environment deletion
Once you have finished with your environment - the components can easily be deleted. Either from AWS EC2 console or using CLI tools, first delete each of the login node and compute node CloudFormation stacks, then the network stack last. All resources will be deleted leaving your AWS account in the state it was, with no hidden resources. 

###Automatically scaling compute nodes
You can easily add automatic scaling functionality to your autoscaling compute group. The CloudWatch alarms will monitor each deployed autoscaling group you choose - increasing and decreasing the number of nodes available as your workload increases and decreases. 

For this example - assume that our autoscaling group stack we previously created is named `alces-cluster-compute-2287`. 

First - get the ID of the autoscaling group, this can be done with the following command: 

```bash
ASGID=(aws cloudformation describe-stacks \
	--stack-name alces-cluster-compute-2287 | \
	grep OutputValue | \
        awk '{print $4}')
```

Use the obtained autoscaling group ID to attach the CloudWatch monitoring alarms and policies to: 

```bash
ASG=MyASGID
aws cloudformation create-stack \
	--stack-name ${ASG}-monitor \
        --template-body file://templates/monitor.json \
	--parameters ParameterKey=ASG,ParameterValue="$ASG"
```

##Alces Storage Manager
To deploy an Alces Storage Manager appliance to manage your storage including file and object storage - complete the following steps. A default Alces Storage Manager appliance AMI ID is included in the `settings.example` file. 

Source the `settings` file: 

```bash
. settings
```

Launch the Alces Storage Manager appliance - choosing an instance type to launch with, this sets the number of cores and memory available to the instance. 

```bash
STORAGETYPE="c4.large"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-storage-manager \
	--template-body file://templates/storage-manager.json \
	--parameters ParameterKey=STORAGETYPE,ParameterValue="$STORAGETYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=NODENAME,ParameterValue="$NODENAME" \
                     ParameterKey=STORAGEMGRAMI,ParameterValue="$STORAGEMGRAMI" \
                     ParameterKey=LOGINIP,ParameterValue="$LOGINIP" 
```

Once the Storage Manager stack has successfully creatd - you can get its access IP through the `describe-stacks` feature: 

```bash
aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-storage-manager | \
	grep OutputValue | \
        awk '{print $4}'
```

Once you have gained the IP - log in to the instance using SSH. Once you are on the Storage Manager appliance - you can gain its automatically generated public host name, for example: 

```bash
[alces@storage-manager(alces-cluster) ~]$ alces about environment
      Clusterware release: 2016.03
         Public host name: storage.alces-cluster.cloud.compute.estate
         Clusterware name: storage.alces-cluster
       Platform host name: ec2-52-50-113-44.eu-west-1.compute.amazonaws.com
        Public IP address: 52.50.113.44
```

You will also need to set a password on your cluster login node of the user account you would like to log in to the Storage Manager interface with, for example: 

```bash
[alces@login1(alces-cluster) ~]$ passwd
Changing password for user alces.
Changing password for alces.
(current) UNIX password:
```

The storage from your cluster is automatically added to the Storage Manager with no configuration necessary. See more on [using Alces Storage Manager](http://alces-flight-appliance-docs.readthedocs.org/en/aws-v1.2.1/clusterware-storage/alces-storage-overview.html) 

##Application Manager deployment
To deploy an Alces Application Manager appliance to your environment, use the following commands: 

Source the `settings` file: 

```bash
. settings
```

```bash
APPTYPE="c4.large"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-app-manager \
	--template-body file://templates/app-manager.json \
	--parameters ParameterKey=APPTYPE,ParameterValue="$APPTYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=APPMGRAMI,ParameterValue="$APPMGRAMI" 
```

Once the Application Manager stack has successfully deployed - obtain both its internal IP (for future use) and external IP for access and customisation: 

```bash
APPMGRIP=$(aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-app-manager | \
	grep InternalIP | \
        awk '{print $4}')
echo "APPMGRIP=\"${APPMGRIP}\"" >> settings
```

Get the public access IP: 

```bash
aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-app-manager | \
        grep AccessIP | \
        awk '{print $4}'
```

##Galaxy environment deployment
To deploy a single-node Galaxy compute environment - hosted on a single instance, use the following commands: 

Source the `settings` file: 

```bash
. settings
```

```bash
GALAXYTYPE="c4.large"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-galaxy \
	--template-body file://templates/galaxy.json \
	--parameters ParameterKey=GALAXYTYPE,ParameterValue="$GALAXYTYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=GALAXYAMI,ParameterValue="$GALAXYAMI" 
```

Add the Galaxy master nodes internal IP to the `settings` file for later use: 

```bash
GALAXYIP=$(aws cloudformation describe-stacks \
	--stack-name ${CLUSTERNAME}-galaxy | \
	grep InternalIP | \
        awk '{print $4}')
echo "GALAXYIP=\"${GALAXYIP}\"" >> settings
```

###Adding additional nodes
For when a single node is not enough - additional compute nodes can be dynamically added to your Galaxy compute environment

####Adding single nodes
To add a single node at a time, follow the below steps: 

Source the `settings` file: 

```bash
. settings
```

```bash
COMPUTETYPE="c4.large"
aws cloudformation create-stack \
	--stack-name ${CLUSTERNAME}-galaxy-node \
	--template-body file://templates/galaxy-node.json \
	--parameters ParameterKey=COMPUTETYPE,ParameterValue="$COMPUTETYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=GALAXYIP,ParameterValue="$GALAXYIP" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=GALAXYAMI,ParameterValue="$GALAXYAMI" 
```

####Adding multiple nodes
To add multiple compute nodes using Amazon AutoScaling Groups - follow the below steps: 

Source the `settings` file: 

```bash
COMPUTETYPE="c4.large"
NODENUMBER="5"
aws cloudformation create-stack \
        --stack-name ${CLUSTERNAME}-galaxy-compute-$$ \
        --template-body file://templates/multiple-nodes.json \
        --parameters ParameterKey=COMPUTETYPE,ParameterValue="$COMPUTETYPE" \
                     ParameterKey=VPCID,ParameterValue="$VPCID" \
                     ParameterKey=GATEWAYID,ParameterValue="$GATEWAYID" \
                     ParameterKey=ROUTETABLEID,ParameterValue="$ROUTETABLEID" \
                     ParameterKey=SUBNETID,ParameterValue="$SUBNETID" \
                     ParameterKey=NETWORKACL,ParameterValue="$NETWORKACL" \
                     ParameterKey=SECURITYGROUP,ParameterValue="$SECURITYGROUP" \
                     ParameterKey=CLUSTERNAME,ParameterValue="$CLUSTERNAME" \
                     ParameterKey=KEYPAIR,ParameterValue="$KEYPAIR" \
                     ParameterKey=NODENUMBER,ParameterValue="$NODENUMBER" \
                     ParameterKey=GALAXYAMI,ParameterValue="$GALAXYAMI" \
                     ParameterKey=GALAXYIP,ParameterValue="$GALAXYIP"
```
