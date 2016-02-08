#Alces Flight Appliances on AWS
Deployment templates and additional tools are available - covering both virtual HPC clusters and Galaxy research environments. 

The following deployment templates (using Amazon CloudFormation) are available - 

##Alces Flight Compute Cluster
* Static 4 node environment
  * 1 cluster master node, 3 cluster compute nodes
* Any-node environment with spot compute
  * 1 cluster master node, users choice of compute nodes

##Alces Flight Galaxy environment
* Static single-node environment
  * 1 cluster master node, serving as both webapp and compute host
* Any-node environment with spot compute
  * 1 cluster master node, users choice of compute nodes

##Tools and extras
Additional tools and utilities are available to help with the administration of your environment, including:

* [Automatically scaling your compute hosts](https://github.com/alces-software/flight-appliance-support/blob/1.0/aws-cloudformation/aws-extras/add-compute/add-compute.sh) (spot compute clusters only)
  * Through the provided script - additional compute hosts can be automatically deployed to your environment, with no configuration necessary

#Read the documentation
Accompanying documentation for deployment techniques are available at readthedocs:

* http://alces-flight-appliance-docs-aws.readthedocs.org/en/latest/
