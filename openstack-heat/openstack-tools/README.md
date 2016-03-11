#How to launch an Alces Compute environment using CLI
An Alces environment can be launched using your local workstation together with the OpenStack command-line tools. 

##Prerequisites
* For information on the installation of the OpenStack command-line tools, please [visit the OpenStack how-to](http://docs.openstack.org/cli-reference/common/cli_install_openstack_command_line_clients.html)
* Optionally - if using an Alces OpenStack environment, your cluster login node(s) will have the OpenStack command-line tools already installed. 
* [OpenStack access configuration file downloaded](http://docs.openstack.org/cli-reference/common/cli_set_environment_variables_using_openstack_rc.html) to your workstation or login node
* If using an Alces OpenStack environment - a VPN connection to the DMZ network must be established
* Clone the `alces-software/flight-appliance-support` Git repository

#Environment deployment
The environment deployment guide includes end-to-end deployment of a complete research environment, including a private cluster network - segregating your compute environment from other users in your OpenStack environment. 

Navigate to the `openstack-heat/openstack-tools` directory within the previously cloned out Git repository, then continue with the below steps to start launching your environment. 

##Network deployment
The following steps will automatically create a segregated cluster network for your compute hosts to live in, creating a completely isolated environment from other instances in your current project. 

Note - the values used in the Heat templates assume an Alces OpenStack installation. 

To begin, source the OpenStack RC file to authenticate to your project - this is usually performed with: 

```
source project-openrc.sh
```

Run the following command to create your network. Note, the `research1` stack name should be replaced with the exact value of the cluster name you wish to deploy, it is important this is the same throughout to ensure correct configuration.

```bash
heat stack-create research1 \
	-t 60 -r \
	-f templates/network.yaml
+--------------------------------------+------------+--------------------+----------------------+
| id                                   | stack_name | stack_status       | creation_time        |
+--------------------------------------+------------+--------------------+----------------------+
| 166e5743-6f60-46c4-a718-64368a2c53b4 | research1  | CREATE_IN_PROGRESS | 2016-03-10T15:52:59Z |
+--------------------------------------+------------+--------------------+----------------------+
```	

Once the stack has finished creating - gather information to be used later on when creating compute hosts. Use the `heat stack-show <stackname>` command to get a list of outputs, providing information about your created infrastructure stack: 

```bash
[alces-cluster@login1(demo) ~]$ heat stack-show research1
insert placeholder here 
```

Select the `cluster_uuid`, `cluster_token`, `image` and `cluster_name` output values - and enter them into the appropriate fields in the `compute.yaml` file. For example, a populated `compute.yaml` file would look like: 

```yaml
parameters:
  # Select an instance flavour to use. This defines
  # the number of CPU cores and memory available
  compute_flavour: m1.medium

  # Enter the `cluster_uuid` value obtained from
  # your infrastructure stack output
  cluster_uuid: 701986198346777918678467

  # Enter the `cluster_token` value obtained from
  # your infrastructure stack output
  cluster_token: ri8oYpt70INvLxtXFoWe

  # Enter the `cluster_name` value obtained from
  # your infrastructure stack output
  cluster_name: research1

  # Enter the Alces Flight Compute appliance
  # image to deploy. Check the image exists in
  # your environment using:
  # `openstack image list`
  image: centos7-compute-2.1.1
```

##Deploying compute nodes
The following section will detail how to deploy both single compute nodes and groups of compute nodes to your environment, using the previously configured `compute.yaml` file together with your existing infrastructure stack. 

After deploying compute nodes - they will automatically join the cluster login node, self-configuring and registering as ready for work through the cluster scheduler. 

###Deploying multiple compute nodes
Using the AutoScaling Groups feature - it is trivial to deploy multiple compute nodes in a group to your existing network. Whilst correctly authenticated to your OpenStack project using the OpenStack RC file - run the following commands to add multiple compute nodes to your environment:

```bash
heat stack-create research1-computegroup \
	-e compute.yaml \
	-t 60 -r \
	-f templates/compute-group.yaml \
	-P compute_number=5
+--------------------------------------+------------------------+--------------------+----------------------+
| id                                   | stack_name             | stack_status       | creation_time        |
+--------------------------------------+------------------------+--------------------+----------------------+
| 166e5743-6f60-46c4-a718-64368a2c53b4 | research1              | CREATE_COMPLETE    | 2016-03-10T15:52:59Z |
| 800f9986-916f-44c3-a5fc-99e785707712 | research1-computegroup | CREATE_IN_PROGRESS | 2016-03-10T16:55:22Z |
+--------------------------------------+------------------------+--------------------+----------------------+
```

###Deploying a single node
Whilst correctly authenticated to your OpenStack project using the OpenStack RC file - run the following commands to add a single compute node to your environment. 

First - verify the settings in the `compute.yaml` settings file - once you have confirmed the settings, launch a single node into the environment using the following command - the `node_name` value should be unique, check which nodes exist in your environment first. 

```bash
heat stack-create research1-compute-node10 \
	-e compute.yaml \
	-t 60 -r \
	-f templates/compute-single.yaml \
	-P node_name=node10
+--------------------------------------+--------------------------+--------------------+----------------------+
| id                                   | stack_name               | stack_status       | creation_time        |
+--------------------------------------+--------------------------+--------------------+----------------------+
| 166e5743-6f60-46c4-a718-64368a2c53b4 | research1                | CREATE_COMPLETE    | 2016-03-10T15:52:59Z |
| 442a9775-3626-4f34-b285-6e1868d9190a | research1-computegroup   | CREATE_COMPLETE    | 2016-03-10T17:10:02Z |
| 04cbdb3a-6ee9-41f8-8ddd-0bf89865b706 | research1-compute-node10 | CREATE_IN_PROGRESS | 2016-03-10T17:29:58Z |
+--------------------------------------+--------------------------+--------------------+----------------------+
```
