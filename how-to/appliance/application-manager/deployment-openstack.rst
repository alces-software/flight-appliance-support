Alces Flight Application Manager Deployment
===========================================

The following steps detail the deployment process of the Alces Flight Application Manager appliance, which provides configuration management and assists with deployment of compute environments. 

The following guide will deploy a single Flight Application Manager appliance in the ``primary`` project - intended for use by any user of the ``primary`` project. Optionally, you may wish to deploy Flight Application Manager appliances in your own projects, or on different OpenStack networks. 

**Prerequisites**
 * Alces OpenStack user account
 * Correctly connected to the cluster DMZ network VPN
 * Appropriate resource quota to create the number of compute nodes you choose
 * OpenStack keypair added

Deploying the Application Manager
---------------------------------

Using the OpenStack Horizon web interface, log in with your site credentials. 

1.  Navigate to the ``Project -> Compute -> Instances`` page
2.  Click the ``Launch Instance`` button
3.  From the ``Details`` tab, select the following options:
  -  **Availability Zone**: ``nova``
  -  **Instance Name**: ``app-manager1``
  -  **Flavor**: Select the instance size you desire, this sets the number of cores and memory available. We recommend at least 2 cores/4GB memory
  -  **Instance Count**: ``1``
  -  **Instance Boot Source**: ``Boot from image``
  -  **Image Name**: Select the latest ``centos7-flight-application-manager`` image
4.  From the ``Access & Security`` tab, select the following options:
  -  **Key Pair**: Select your OpenStack keypair, this is used for administrator access to the application manager
  -  **Security Groups**: ``default``
5.  From the ``Networking`` tab, select the following options: 
  -  **Selected Networks**: ``internal``
6.  Press the ``Launch`` button
7.  Using the dropdown menu in the ``Actions`` column for your instance - select the ``Associate Floating IP`` option - and choose a floating IP to assign to your application manager. 

Your Flight Application Manager appliance is now ready for use and customisation in preparation of deploying compute environments. 

Customising the Application Manager
-----------------------------------

Gain an SSH session on the Application Manager appliance using the previously assigned floating IP address, together with the ``alces`` administrator user. 

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

The following steps will detail the process to deploy a compute environment using the configuration from the Application Manager appliance. First - log in to the Horizon dashboard. 

1.  Navigate to the ``Project -> Compute -> Instances`` page
2.  Click ``Launch Instance``
3.  From the ``Details`` tab, select the following options:
  -  **Availability Zone**: ``nova``
  -  **Instance Name**: ``login1``
  -  **Flavor**: Select the instance size you desire, this sets the number of cores and memory available.
  -  **Instance Count**: ``1``
  -  **Instance Boot Source**: ``Boot from image``
  -  **Image Name**: Select the latest ``centos7-flight-app-manager-image`` image
4.  From the ``Access & Security`` tab, select the following options:
  -  **Key Pair**: Select your OpenStack keypair, this is used for access to the environment 
  -  **Security Groups**: ``default``
5.  From the ``Networking`` tab, select the following options: 
  -  **Selected Networks**: ``internal``
6.  From the ``Post-creation`` tab, perform the following: 
  - **Customization Script Source**: ``Direct Input`` - enter the following cloud-config. Note - the ``cw_BOOTSTRAP_app_manager_address`` field should be changed to the internal IP address of your Application Manager appliance previously noted - and the ``cw_BOOTSTRAP_cluster_name`` field should be replaced with your desired cluster name, e.g. ``research1`` 

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
        cw_BOOTSTRAP_role=login
      path: /etc/xdg/clusterware/bootstrap.rc
      permissions: 0600

7.  Press the ``Launch`` button
8.  Using the dropdown menu in the ``Actions`` column for your instance - select the ``Associate Floating IP`` option - and choose a floating IP to assign to your cluster login node. 

To deploy compute nodes, repeat the above steps - but change the following details during creation: 

-  **Instance Name**: ``nodeX`` - increment for each deployed node
-  **Key Pair**: Do not select a key pair for compute nodes
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
