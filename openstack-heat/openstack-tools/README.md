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

##Network and infrastructure node deployment
The following steps will automatically create a segregated cluster network for your compute hosts to live in, creating a completely isolated environment from other instances in your current project. The steps will also create a cluster master node, used to host scheduler services and run your environment. 

Note - the values used in the Heat templates assume an Alces OpenStack installation. 

To begin, source the OpenStack RC file to authenticate to your project - this is usually performed with: 

```
source project-openrc.sh
```

Open the ``infrastructure.yaml`` file for editing - this will configure your environment with the values included. 

For each of the parameters in the file, edit them with your preferred choice - most importantly: 

* `admin_key`
* `cluster_name`

Once you have finished editing the ``infrastructure.yaml`` file, save and exit - you can now deploy your network and login node using the following command: 

```bash
heat stack-create research1 \
	-e infrastructure.yaml \
	-t 60 -r \
	-f templates/network-login.yaml
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
| creation_time         | 2016-03-10T15:52:59Z                                                                                                      |
| description           | Create an isolated network for use with an Alces                                                                          |
|                       | compute environment.                                                                                                      |
| disable_rollback      | False                                                                                                                     |
| id                    | 166e5743-6f60-46c4-a718-64368a2c53b4                                                                                      |
| links                 | http://10.78.254.10:8004/v1/06c2c75c14514ca0880e987398ec4a76/stacks/research1/166e5743-6f60-46c4-a718-64368a2c53b4 (self) |
| notification_topics   | []                                                                                                                        |
| outputs               | [                                                                                                                         |
|                       |   {                                                                                                                       |
|                       |     "output_value": "10.77.2.179",                                                                                        |
|                       |     "description": "Access IP of cluster login node",                                                                     |
|                       |     "output_key": "login1_public_ip"                                                                                      |
|                       |   },                                                                                                                      |
|                       |   {                                                                                                                       |
|                       |     "output_value": "701986198346777918678467",                                                                           |
|                       |     "description": "Cluster unique ID",                                                                                   |
|                       |     "output_key": "cluster_uuid"                                                                                          |
|                       |   },                                                                                                                      |
|                       |   {                                                                                                                       |
|                       |     "output_value": "ri8oYpt70INvLxtXFoWe",                                                                               |
|                       |     "description": "Cluster unique token",                                                                                |
|                       |     "output_key": "cluster_token"                                                                                         |
|                       |   }                                                                                                                       |
|                       | ]                                                                                                                         |
| parameters            | {                                                                                                                         |
|                       |   "OS::project_id": "06c2c75c14514ca0880e987398ec4a76",                                                                   |
|                       |   "OS::stack_id": "166e5743-6f60-46c4-a718-64368a2c53b4",                                                                 |
|                       |   "OS::stack_name": "research1",                                                                                          |
|                       |   "image": "centos7-compute-2.1.1",                                                                                       |
|                       |   "cluster_name": "research1",                                                                                            |
|                       |   "compute_flavour": "m1.medium",                                                                                         |
|                       |   "admin_key": "aws_ireland"                                                                                              |
|                       | }                                                                                                                         |
| parent                | None                                                                                                                      |
| stack_name            | research1                                                                                                                 |
| stack_owner           | stackadmin                                                                                                                |
| stack_status          | CREATE_COMPLETE                                                                                                           |
| stack_status_reason   | Stack CREATE completed successfully                                                                                       |
| stack_user_project_id | ece4cdbf4b5a4ec59cce5b0d40acc710                                                                                          |
| template_description  | Create an isolated network for use with an Alces                                                                          |
|                       | compute environment.                                                                                                      |
| timeout_mins          | 60                                                                                                                        |
| updated_time          | None                                                                                                                      |
+-----------------------+---------------------------------------------------------------------------------------------------------------------------+
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
