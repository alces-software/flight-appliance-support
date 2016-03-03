.. _manual-deploy-application-manager.rst

Alces Flight Application Manager Deployment
===========================================

The following steps detail the deployment process of the Alces Flight Application Manager appliance, which provides configuration management and assists with deployment of compute environments. 

The following guide will deploy a single Flight Application Manager appliance in your existing AWS VPC.

**Prerequisites**
 * AWS account with appropriate IAM permissions (root account preferable)
 * EU-WEST-1 (Ireland) region selected
 * AWS keypair added

Deploying the Application Manager
---------------------------------

Using the EC2 web console: 

1.  Navigate to the ``Instances`` page
2.  Select ``Launch Instance``
3.  **Step 1: Choose an AMI** - Select ``Community AMIs`` then using the search box, enter the AMI ID ``ami-ef68d49c``
4.  Select the ``alces-flight-application-manager-1.2.0`` AMI
5.  **Step 2: Choose an Instance Type** - Select the instance type you wish to deploy, this defines the number of CPU cores and memory available. Once selected, press the ``Next: Configure Instance Details`` button
6.  **Step 3: Configure Instance Details** - Leave all fields default, except for the following settings:
  -  **Network**: Choose your existing VPC you wish to deploy the Application Manager into
  -  **Auto-assign Public IP**: Enable
  -  *Optional*: - you may wish to set a hostname for the instance, you can do this using cloud-init in the **Advanced** section, enter the following cloud-config to set a friendly hostname

.. code:: yaml

    #cloud-config
    hostname: app-manager1

7.  Click ``Next: Add Storage``
8.  **Step 4: Add Storage** - Leave the default entries - then click ``Next: Tag Instance``
9.  **Step 5: Tag Instance** - In the ``Name`` field, enter something similar to ``app-manager1``. Once complete, press ``Next: Configure Security Group``
10.  **Step 6: Configure Security Group** - Select or create a security group which allows HTTP and NFS (ports ``111``, ``2049``, ``1110``, ``4045`` TCP & UDP). Once this has been completed, select the ``Review and Launch`` button
11.  Assuming all the details are correct - select the ``Launch`` button to deploy your Flight Application Manager appliance

Your Flight Application Manager appliance is now ready for use and customisation in preparation of deploying compute environments. 

Customising the Application Manager
-----------------------------------

Gain an SSH session on the Application Manager appliance using the public IP address, together with the ``alces`` administrator user and your selected AWS keypair. 

1.  Change to the ``root`` user
2.  Navigate to the ``/opt/clusterware/var/lib/clusterware`` directory
3.  Open the ``bootstrap-node`` file in your editor of choice
4.  Customisations to deployed clusters can be made in the ``bootstrap-node`` file. Initial one-time customisations should be included in the ``# SITE CONFIG PER NODE`` section - and per-boot settings should be included in the ``# SITE CONFIG PER BOOT`` section. 
5.  The included example mounts ``/opt/gridware`` - providing cluster applications - from the Application Manager on each deployed node. Customisations such as distribution package installations and external storage mounts should be included here. 

Sourcing Gridware applications from alternate locations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Gridware applications can also be mounted from locations other than the Application Manager appliance - possible choices include: 

-  Deployed clusters mounting applications from a remote NFS server
-  Clusters create and share their own Gridware repositories, providing separation between environments

Per-environment Gridware repositories
"""""""""""""""""""""""""""""""""""""

To configure deployed environments to each configure and share their own Gridware repositories, the following changes can be made to the ``bootstrap-node`` configuration file on the Flight Application Manager appliance: 

Replace the contents of the ``# SITE CONFIG PER NODE`` with the following: 

.. code:: bash

    configure_site_per_node() {
        # SITE CONFIG PER NODE
    if [ ${cw_BOOTSTRAP_role} == "login" ]; then
      yum -y install nfs-utils
      systemctl enable nfs-server
      systemctl restart rpcbind
      systemctl start nfs-server
      mkdir -p /opt/gridware
      cat << EOF > /etc/exports
      /opt/gridware/ *(rw,no_root_squash,no_subtree_check,sync)
      EOF
      PATH=/opt/clusterware/bin:$PATH
      export cw_UI_disable_spinner=true
      alces gridware init
      exportfs -ra
    else
      mkdir -p /opt/gridware
    fi
        :
    }

Replace the contents of the ``# SITE CONFIG PER BOOT`` section, with the following: 

.. code:: bash

    configure_site_per_boot() {
        # SITE CONFIG PER BOOT
    if [ ${cw_BOOTSTRAP_role} == "compute" ]; then
      mount -t nfs login1:/opt/gridware /opt/gridware
    fi
        :
    }

6. Finally - note down the internal IP address of the Application Manager appliance, for example ``192.168.50.50``

Deploying an SGE compute environment
------------------------------------

The following steps will detail the process to deploy a compute environment using the configuration from the Application Manager appliance. First - log in to the EC2 console. 

1.  Navigate to the ``Instances`` page
2.  Select ``Launch Instance``
3.  **Step 1: Choose an AMI** - Select ``Community AMIs`` then using the search box, enter the AMI ID ``ami-d4378ba7``
4.  Select the ``alces-flight-app-manager-image-1.2.0`` AMI
5.  **Step 2: Choose an Instance Type** - Select the instance type you wish to deploy, this defines the number of CPU cores and memory available. *Note* - we recommend at least 2 cores/4GB memory for a compute instance. Once selected, press the ``Next: Configure Instance Details`` button
6.  **Step 3: Configure Instance Details** - Leave all fields default, except for the following settings:
  -  **Network**: Choose your existing VPC you wish to deploy the environment into. This must be the same as the previously deployed Application Manager appliance. 
  -  **Auto-assign Public IP**: Enable
  -  **Advanced**: - using the input field, enter the following cloud-config data. Replace the ``cw_BOOTSTRAP_app_manager_address`` and ``cw_BOOTSTRAP_cluster_name`` fields with the internal IP address of your Application Manager appliance, and your chosen cluster name - for example:

.. code:: yaml

    #cloud-config
    hostname: login1
    write_files:
    - content: |
        cw_BOOTSTRAP_dist=el7
        cw_BOOTSTRAP_app_manager_address=192.168.150.148
        cw_BOOTSTRAP_root=/opt/clusterware
        cw_BOOTSTRAP_cluster_uuid=7d1fc45b-dbe3-47ed-af4d-b66e74e710f4
        cw_BOOTSTRAP_cluster_token=qU/wUgZN1oZ1J6a+4LRH
        cw_BOOTSTRAP_cluster_name=alces-cluster
        cw_BOOTSTRAP_role=login
      path: /etc/xdg/clusterware/bootstrap.rc
      permissions: 0600

7.  Click ``Next: Add Storage``
8.  **Step 4: Add Storage** - Leave the default entries - then click ``Next: Tag Instance``
9.  **Step 5: Tag Instance** - In the ``Name`` field, enter something similar to ``login1``. Once complete, press ``Next: Configure Security Group``
10.  **Step 6: Configure Security Group** - Select or create a security group which allows HTTP and NFS (ports ``111``, ``2049``, ``1110``, ``4045`` TCP & UDP). Once this has been completed, select the ``Review and Launch`` button
11.  Assuming all the details are correct - select the ``Launch`` button to deploy your Flight Application Manager appliance
12.  Press the ``Launch`` button

To deploy compute nodes, repeat the above steps - but change the following details during creation: 

-  **Instance Name**: ``nodeX`` - increment for each deployed node
-  **Customization Script Source**: Enter the following cloud-config for compute nodes, modifying the ``cw_BOOTSTRAP_cluster_name`` and ``cw__BOOTSTRAP_app_manager_address`` fields as previously done: 

.. code:: yaml

    #cloud-config
    write_files:
    - content: |
        cw_BOOTSTRAP_dist=el7
        cw_BOOTSTRAP_app_manager_address=192.168.150.148
        cw_BOOTSTRAP_root=/opt/clusterware
        cw_BOOTSTRAP_cluster_uuid=7d1fc45b-dbe3-47ed-af4d-b66e74e710f4
        cw_BOOTSTRAP_cluster_token=qU/wUgZN1oZ1J6a+4LRH
        cw_BOOTSTRAP_cluster_name=alces-cluster
        cw_BOOTSTRAP_role=compute
      path: /etc/xdg/clusterware/bootstrap.rc
      permissions: 0600

Your environment has now been deployed, consisting of a cluster login node - hosting batch scheduler services, as well as dedicated compute nodes; each of these nodes has been deployed using the Flight Application Manager appliance, gathering configuration information and system setup. 
