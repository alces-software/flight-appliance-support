Alces Flight Compute on Azure
=============================

The following steps will cover how to create the required resources to form an Alces Flight Compute cluster on Azure public cloud. This guide primarily uses the Azure command-line tools from within the Azure Portal for cluster creation and configuration, so it is preferable that you have experience with the Azure CLI. This guide also assumes the following prerequisites have been met:

* An SSH keypair
* An SSH client
* A Microsoft Azure account

Getting started
---------------

To get set up, ready to start creating your Alces Flight Compute environment - follow the below steps:

* Log in to the [Azure Portal](https://portal.azure.com)
* Start a new command-line tools session (Linux). If this is your first time using the Azure Portal command-line interface, you may need to create a new storage account using the creation wizard. You can start a new command-line sesion within the Azure Portal by clicking the `>_` icon in the toolbar:

![CLI icon](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-cli.png)

* Once you have completed the above steps, you will be able to use the Azure CLI tools (2.0) from within your browser.

Creating a Resource Group
-------------------------

Resource Groups are used to easily group collections of assets of a similar nature - in this guide we will create a new Resource Group, which we will add all created resources into.

* Using the Azure Portal CLI pane - create a new Resource Group. The Resource Group name must be unique. You will also need to choose a region when creating your resource group - this will mean all later deployed resources will be deployed into the same region as the Resource Group. Either save the Resource Group name as a variable in your CLI session, or remember it for later use:

![Resource Group creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-resourcegroup.png)

```bash
export az_RESOURCE_GROUP="flight-compute-demo"
az group create -l uksouth -n $az_RESOURCE_GROUP
```

Configuring the cluster network
-------------------------------

A cluster network needs to be created, along with the appropriate security group rules to provide SSH access to the Alces Flight cluster. We recommend using the configuration shown below:

* Using the Azure Portal CLI pane - create a new cluster network:

![Network creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-resourcegroup.png)

```bash
az network vnet create -g $az_RESOURCE_GROUP -n flight-compute-demo --address-prefix 10.0.0.0/24 --subnet-name prv --subnet-prefix 10.0.0.0/24
```

* Using the Azure Portal CLI pane - create a new security group, rules will be then attached to the security group later on. When creating a new security group - Azure adds some default, useful rules:

![Security Group creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-securitygroup.png)

```bash
az network nsg create -n flight-compute-demo -g $az_RESOURCE_GROUP
```

* Next, a rule to allow inbound SSH access needs to be added to the security group. Again, from the Azure Portal CLI pane - create a new security group rule:

![Security Group rule creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-securitygrouprule.png)

```bash
az network nsg rule create \
-g $az_RESOURCE_GROUP \
--nsg-name flight-compute-demo \
-n ingress-ssh \
--protocol Tcp \
--priority 1000 \
--destination-port-range 22 \
--access allow
```

Configuring Alces Flight Compute cluster settings
-------------------------------------------------

The Alces Flight Compute cluster requires a few shared settings between login and compute hosts, these include:

* Cluster UUID - you can generate a UUID either at https://www.uuidgenerator.net/ or on your own machine using `uuidgen`
* Cluster token - you can generate a token in the Azure CLI portal using `openssl rand -hex 8`
* Cluster name - choose a cluster name, this customizes your cluster and sets up networking

![Flight Configuration](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-flightconfig.png)

```bash
export alces_FLIGHT_UUID=1ed73764-1151-471c-8805-8b87889a9c1d
export alces_FLIGHT_TOKEN=$(openssl rand -hex 8)
export alces_FLIGHT_CLUSTER_NAME="flight-demo"
```

Creating the Alces Flight Compute login node
--------------------------------------------

The login node is responsible for cluster management including cluster scheduler master and providing shared storage for applications etc.

* Using the Azure Portal CLI pane, create a new login node. Note down the private IP address, this is required to correctly create compute nodes. If you used a different network range, the IP address shown in the below example may not work:

![Login node creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-login1.png)

```bash
az vm create -n login1 -g $az_RESOURCE_GROUP --image "/subscriptions/d1e964ef-15c7-4b27-8113-e725167cee83/resourceGroups/alcesflight/providers/Microsoft.Compute/images/alces-flight-compute-1.0.0-beta" --custom-data "bash /opt/alces/helper --cluster-name $alces_FLIGHT_CLUSTER_NAME --type master --uuid $alces_FLIGHT_UUID --token $alces_FLIGHT_TOKEN" --size Standard_DS1_v2 --admin-username alces --ssh-dest-key-path "/home/alces/.ssh/authorized_keys" --ssh-key-value "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA+S71+zvHiiH+gFFCSsMs+VZIRLeh29JeDu5z5Y0F+Sg1kmLOQLqr7u2qA6FHTwz4vMMvqW2h3mvYUvW2nGOJec9fkY2cCPrFzSvu/6+44Zirv9Zmm7l9Brozj+7jdatNTmTlfEXUlGZIMxOeXdC/Shkmrajadg9pngaCnzxZaoFFoXfnY5Xf/dR/dgbnHr9tKHY7jDMggFnPEvC8NUCAFYg2HuZVfFjiYn4ptv00TYFhf1m2RX/RNUzR+qpltOZEYww3YAb2MgTZtWgQQPmOCAjbwnLSmwvuijEAiVLlE/wKqI05wr1z2viVC1r9u7Cg+uOD/4X8adoyALx+grsv" --nsg flight-compute-demo --private-ip-address 10.0.0.4 --subnet prv --vnet-name flight-compute-demo
```

After a few minutes, you should then be able to log into your Alces Flight Compute login instance using the administrator username and keypair previously specified - together with the `publicIpAddress` displayed when creating the login instance:

![Login node access](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-login1access.png)

Compute node creation
---------------------

Next, a compute node can be created. This process can be repeated for as many compute nodes you wish to deploy.

* Using the Azure Portal CLI pane, create a compute node. It is important to include the correct cluster and login node configuration in order for the compute nodes to correctly configure themselves:

![Compute node creation](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-node01.png)

```bash
az vm create -n node01 -g $az_RESOURCE_GROUP --image "/subscriptions/d1e964ef-15c7-4b27-8113-e725167cee83/resourceGroups/alcesflight/providers/Microsoft.Compute/images/alces-flight-compute-1.0.0-beta" --custom-data "bash /opt/alces/helper --cluster-name $alces_FLIGHT_CLUSTER_NAME --type slave --master-ip 10.0.0.4 --uuid $alces_FLIGHT_UUID --token $alces_FLIGHT_TOKEN" --size Standard_DS1_v2 --admin-username alces --ssh-dest-key-path "/home/alces/.ssh/authorized_keys" --ssh-key-value "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA+S71+zvHiiH+gFFCSsMs+VZIRLeh29JeDu5z5Y0F+Sg1kmLOQLqr7u2qA6FHTwz4vMMvqW2h3mvYUvW2nGOJec9fkY2cCPrFzSvu/6+44Zirv9Zmm7l9Brozj+7jdatNTmTlfEXUlGZIMxOeXdC/Shkmrajadg9pngaCnzxZaoFFoXfnY5Xf/dR/dgbnHr9tKHY7jDMggFnPEvC8NUCAFYg2HuZVfFjiYn4ptv00TYFhf1m2RX/RNUzR+qpltOZEYww3YAb2MgTZtWgQQPmOCAjbwnLSmwvuijEAiVLlE/wKqI05wr1z2viVC1r9u7Cg+uOD/4X8adoyALx+grsv" --nsg flight-compute-demo --subnet prv --vnet-name flight-compute-demo
```

Next steps
----------

The following resources were created:

* Resource Group
* Cluster network and subnet
* Inbound SSH access security group rules
* Alces Flight login node
* Alces Flight compute node

A few minutes after creating your first compute node, it should be available to use through the cluster scheduler:

![Compute node access](https://s3-eu-west-1.amazonaws.com/flight-appliance-support/images/azure-node01access.png)

You can learn more about using an Alces Flight Compute cluster in the [Alces Flight Compute documentation](http://docs.alces-flight.com)
