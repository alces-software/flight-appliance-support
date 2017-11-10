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
