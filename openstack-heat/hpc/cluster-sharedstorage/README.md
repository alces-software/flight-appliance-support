Deploy an Alces Flight compute environment with shared scratch storage using OpenStack Heat
===========================================================================================

The following steps will provide you with an Alces ClusterWare SGE cluster, complete with Gridware applications and all required OpenStack networking services. The cluster also includes a configurable amount of shared NFS storage, also known as scratch storage. The cluster is comprised of a single user accessible login node and SGE compute nodes, with customisable instance types.

**Prerequisites**  
-   Alces OpenStack user account
-   Correctly connected to the cluster DMZ network
-   Appropriate resource quota to create the number of compute nodes you choose
-   OpenStack keypair added

Deploying via Horizon web interface
-----------------------------------

1.  Log in to the OpenStack Horizon interface with your site credentials
2.  Navigate to the `Project -> Orchestration -> Stacks` page
3.  Select the `Launch Stack` button

4. **Template Source**: Select `URL` and enter the following template URL:  
-   `https://raw.githubusercontent.com/alces-software/flight-appliance-support/1.0/openstack-heat/hpc/X-node-cluster.yaml`

1.  **Environment Source**: *Not required*
2.  Click the `Next` button
3.  **Stack Name**: Enter a stack name, this defines the cluster name
4.  **Creation Timeout (minutes)**: Leave default `60`
5.  **Rollback On Failure**: `Enabled`
6.  **Password for user**: Enter your OpenStack user password
7.  **Cluster admin key**: Select your OpenStack keypair to assign to the administrator user account
8.  **HPC Image**: Select the Alces Compute image from the list of available images
9.  **Instance Type**: Select the instance type to deploy, this defines the number of cores and memory available to each instance
10. **Number of compute nodes**: Enter the number of dedicate compute nodes you wish to deploy
11. **Gridware Depot**: Select the Gridware depot to install. Gridware depots install packs of popular applications for certain use-cases.
12. **Storage size**: Enter the size in GB of shared scratch storage to deploy on your cluster. Note - you should have the appropriate resource available to provision the amount of storage requested
13. Click the `Launch` button.
14. Once the stack is in `Status: Create In Progress` - enter the stack and navigate to the `Overview` tab
15. Once the stack has finished creating, the `Overview` tab will provide you with the cluster public IP address, used to log in with the administrator user `alces`

Access your environment
-----------------------

1.  From the `Overview` tab of your stack, make a note of the cluster master node public IP address displayed, e.g. `10.77.0.100`
2.  SSH to the public IP address as the `alces` administrator account - together with your previously selected OpenStack keypair, e.g. `ssh -i ~/.ssh/openstack\_key.pem alces@10.77.0.100`
