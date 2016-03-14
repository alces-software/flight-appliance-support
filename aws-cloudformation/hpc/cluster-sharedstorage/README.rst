Deploy an Alces Flight compute environment with shared scratch storage using CloudFormation 
===========================================================================================

The following steps will provide you with an Alces Flight SGE cluster, complete with Gridware applications and all required AWS networking services. The cluster also includes a configurable amount of shared NFS storage, also known as scratch storage. The cluster is comprised of a single user accessible login node and SGE compute nodes, with customisable instance types. 

**Prerequisites**
 * `EU-WEST-1` / Ireland region selected
 * AWS key pair previously uploaded
 * Appropriate IAM privileges (root account preferable) 
 * CloudFormation template from repo downloaded to workstation

Deploying via CloudFormation console 
------------------------------------

1.  Log in to the AWS console and navigate to the CloudFormation console 
2.  Click ``Create Stack``
3.  Select the ``Upload a template to Amazon S3`` option, then upload the previously saved CloudFormation template from your workstation
4.  Click ``Next`` to begin configuring your environment 
5.  Enter a ``stack name``, for example ``researchcluster1``
6.  Select your desired AWS key pair from the list of available keys. This is used to access the cluster administrator account (``alces``). If no AWS key pair is selected - the cluster will fail to create.
7.  Select the Gridware Depot to install, depots install a pack of applications, e.g. ``benchmark`` installs a selection of popular benchmarking utilities
8.  Select the number of compute nodes you wish to deploy 
9.  Select the instance type to deploy (``small`` or ``large``). Small nodes each have 2 cores and 3.75GB memory, large nodes each have 16 cores and 30GB memory. 
10.  Enter a ``NetworkCIDR`` if you would like to restrict access to your environment for increased security
11.  Select the maximum bid per hour for each instance within the compute environment. We recommend leaving the bid at the default ``0.50USD`` 
12.  Enter the size in GB of the shared storage to deploy to your environment, for example to deploy 5TB of shared storage, enter ``5000``
13.  Click ``Next``
14.  On the ``Tags`` page, press the ``Next`` button
15.  On the ``Review`` page, press the ``Create`` button
16.  Your cluster will now begin deploying, view the ``Overview`` tab for status updates

Access your environment
-----------------------

1.  From the ``Overview`` tab of your stack, make a note of the cluster master node public IP address displayed, e.g. ``10.77.0.100``
2.  SSH to the public IP address as the ``alces`` administrator account - together with your previously selected OpenStack keypair, e.g. ``ssh -i ~/.ssh/openstack_key.pem alces@10.77.0.100``

Using your environment
----------------------

-  Read the `environment usage guides <http://alces-flight-appliance-docs.readthedocs.org/en/latest/getting-started/environment-usage/environment_usage.html>`_

Destroying your environment
---------------------------

1.  From the EC2 console - navigate to the CloudFormation page
2.  Select your previously created stack
3.  Click ``Delete Stack``
4.  All previously created resources will be destroyed, including any data stored. 
