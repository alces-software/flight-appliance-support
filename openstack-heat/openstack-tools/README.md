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
+-----------------------+---------------------------------------------------------------------------------------------------------------------------+
| Property              | Value                                                                                                                     |
+-----------------------+---------------------------------------------------------------------------------------------------------------------------+
| capabilities          | []                                                                                                                        |
| creation_time         | 2016-03-11T09:36:23Z                                                                                                      |
| description           | Create an isolated network for use with an Alces                                                                          |
|                       | compute environment.                                                                                                      |
| disable_rollback      | False                                                                                                                     |
| id                    | 558bfe1e-61a8-405d-9e5b-8c765ebc5500                                                                                      |
| links                 | http://10.78.254.10:8004/v1/06c2c75c14514ca0880e987398ec4a76/stacks/research1/558bfe1e-61a8-405d-9e5b-8c765ebc5500 (self) |
| notification_topics   | []                                                                                                                        |
| outputs               | [                                                                                                                         |
|                       |   {                                                                                                                       |
|                       |     "output_value": "fdc8fb16-b699-4b63-9084-f5aaaf81fc3c",                                                               |
|                       |     "description": "Cluster network ID",                                                                                  |
|                       |     "output_key": "network_id"                                                                                            |
|                       |   },                                                                                                                      |
|                       |   {                                                                                                                       |
|                       |     "output_value": "999184fb-cd54-4254-9345-20a16b686c6b",                                                               |
|                       |     "description": "Cluster subnet ID",                                                                                   |
|                       |     "output_key": "subnet_id"                                                                                             |
|                       |   }                                                                                                                       |
|                       | ]                                                                                                                         |
| parameters            | {                                                                                                                         |
|                       |   "OS::project_id": "06c2c75c14514ca0880e987398ec4a76",                                                                   |
|                       |   "OS::stack_id": "558bfe1e-61a8-405d-9e5b-8c765ebc5500",                                                                 |
|                       |   "OS::stack_name": "research1"                                                                                           |
|                       | }                                                                                                                         |
| parent                | None                                                                                                                      |
| stack_name            | research1                                                                                                                 |
| stack_owner           | stackadmin                                                                                                                |
| stack_status          | CREATE_COMPLETE                                                                                                           |
| stack_status_reason   | Stack CREATE completed successfully                                                                                       |
| stack_user_project_id | 5557741a336c4226925a4cc03370bcbb                                                                                          |
| template_description  | Create an isolated network for use with an Alces                                                                          |
|                       | compute environment.                                                                                                      |
| timeout_mins          | 60                                                                                                                        |
| updated_time          | None                                                                                                                      |
+-----------------------+---------------------------------------------------------------------------------------------------------------------------+
```

Select the `network_id` and `subnet_id` output values - then enter them into the appropriate fields in the `login.yaml` file. For example, a populated `login.yaml` file would look like the following. You should also complete the other options, such as `environment_type` and `admin_key`. 

```yaml
parameters:
  # Enter the  unique ID
  # from the output of your network stack
  cluster_network_id: 'fdc8fb16-b699-4b63-9084-f5aaaf81fc3c'

  # Enter the  unique ID
  # from the output of your network stack
  cluster_subnet_id: '999184fb-cd54-4254-9345-20a16b686c6b'

  # Enter the name of your cluster. This
  # should be the name of your network
  # stack, e.g.
  cluster_name: research1

  # Enter the Alces Flight Compute appliance
  # image to deploy. Check the image exists in
  # your environment using:
  # `openstack image list`
  image: centos7-compute-2.1.1

  # Enter the proposed deployment, for
  # example if deploying a HPC compute
  # environment - enter `scheduler`,
  # or if creating a Galaxy environment
  # choose `galaxy`. The type must
  # match the chosen `image` setting
  environment_type: scheduler

  # Enter the name of your OpenStack
  # key pair you wish to use. This
  # provides cluster access
  admin_key: mykeyname
```

##Deploying a cluster login node
Once the network stack has been deployed, and your `login.yaml` environment file has been populated, you can deploy a cluster login node - used to host cluster services. In a `scheduler` environment - the login node runs the scheduler master services, as well as providing node configuration and hosting applications. 

To deploy a cluster login node using your populated `login.yaml` environment file - run the following commands:

```bash
heat stack-create research1-login \
	-e login.yaml \
	-t 60 -r \
	-f templates/login.yaml
```

Once the login node stack has deployed - use the `heat stack-show` command to obtain the output values of the login node stack - add the `cluster_uuid` and `cluster_token` to the `compute.yaml` environment file. The settings should also be configured in the `compute.yaml` file for the deployment of your choice, i.e `scheduler` or `galaxy` - with the appropriate image. 

```yaml
parameters:
  # Select an instance flavour to use. This defines
  # the number of CPU cores and memory available
  compute_flavour: m1.medium

  # Enter the `cluster_uuid` value obtained from
  # your infrastructure stack output
  cluster_uuid: '701986198346777918678467'

  # Enter the `cluster_token` value obtained from
  # your infrastructure stack output
  cluster_token: 'ri8oYpt70INvLxtXFoWe'

  # Enter the `cluster_name` value obtained from
  # your infrastructure stack output
  cluster_name: research1

  # Enter the Alces Flight Compute appliance
  # image to deploy. Check the image exists in
  # your environment using:
  # `openstack image list`
  image: centos7-compute-2.1.1

  # Enter the proposed deployment, for
  # example if deploying a HPC compute
  # environment - enter `scheduler`,
  # or if creating a Galaxy environment
  # choose `galaxy`
  environment_type: scheduler
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
| 558bfe1e-61a8-405d-9e5b-8c765ebc5500 | research1-login        | CREATE_COMPLETE    | 2016-03-10T15:59:29Z |
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

#Deploying a Galaxy environment
Once you have completed the *network deployment* stage, a Galaxy environment can easily be deployed into your network. 

* Repeat the [login node deployment](#deploy-a-cluster-login-node) steps, with the following modifications: 
  * Select an available Alces Flight Galaxy appliance image
  * Change the `environment_type` to `galaxy`
* Repeat the compute node deployment steps, either [single](#deploying-a-single-node) or [multiple](#deploying-multiple-compute-nodes)
  * Select an available Alces Flight Galaxy appliance image
  * Change the `environment_type` to `galaxy`

#Deploying a Storage Manager
To deploy an Alces Storage Manager to your environment - perform the following steps: 

```bash
heat stack-create research1-storage-manager \
	-e storage-manager.yaml \
	-t 60 -r \
	-f templates/storage-manager.yaml 
```

The stack outputs will display the access IP for the Storage Manager appliance - gather this using `heat stack-show <stackname>`. 

To access the Storage Manager - you must first log on to your cluster login node, and set a password for each of the users you wish to log into Storage Manager as, using the `passwd` command. Once a password has been set - you can gain access to the Storage Manager. 
