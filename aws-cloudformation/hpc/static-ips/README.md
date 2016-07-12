#Alces Flight on AWS: Multiple networks
Included in this repository are;

* Modified CloudFormation template to create multiple subnets within the Flight VPC that form different networks used for different purposes, these include `ext`, `build` and `prv`
* Customisation script for instances to create, attach and configure their `build` and `prv` network interfaces

#Changes to CloudFormation template
To support multiple networks as well as the creation and interaction of additional network interfaces, the following changes have been made to the AWS Flight MarketPlace template. 

##IAM Policies
In order for a node to create, attach and configure its own network interfaces - the following IAM policy rules have been added to the existing IAM policies: 

* `ec2:AttachNetworkInterface` - used to attach both the `build` and `prv` network interfaces for each host
* `ec2:CreateNetworkInterface` - used to create both the `build` and `prv` network interfaces for each host
* `ec2:DeleteNetworkInterface` - used to cleanly delete each of the interfaces when a clean shutdown of a node is performed
* `ec2:DetachNetworkInterface` - used to detach a network interface prior to deleting when a clean shutdown of a node is performed
* `ec2:ModifyNetworkInterfaceAttribute` - used to add the `DeleteOnTerminate` tag to each of the created interfaces to ensure a clean stack destroy

##New subnets
Two new subnets are created within the template to be utilised post-stack-creation, the newly created subnets are: 

* `build` - `10.75.10.0/24`
* `prv` - `10.75.20.0/24`

#Customize script
Performs the following activities: 

* Create new network interfaces for each host, for both the `build` and `prv` networks - using the IP address that (one day) comes from an external source
* Attach each network interface to the appropriate slot, e.g. `build` to `eth1` and `prv` to `eth2`
* Modify each network interface created to add the `DeleteOnTerminate` tag, which ensures the interfaces will be deleted when an instance is uncleanly shut down
* Configure each newly attached interface with the correct IP for the chosen personality (although this is currently just set to an example configuration)
* Bring the interfaces up ready for use

#Known issues

* Not able to limit the IAM permissions, can edit any resource so root on one instance would be able to attach/detach network interfaces for all other instances in that AWS account
* Stack can sometimes fail to delete, despite the `DeleteOnTermination` tag being set - CloudFormation seems to get upset as it doesn't give enough time for the interfaces to delete once the kill signal has been given to the instance(s)
* During SGE member joins, the existing IP addresses for each node entry are replaced by ClusterWare with its `ext` network address
