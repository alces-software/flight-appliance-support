.. _add-and-configure-shared-scratch-storage:

How to add and configure shared scratch storage to your compute environment
===========================================================================

The following guide will detail how to create a Cinder storage volume, attach it to your cluster then share it amongst the environment for use as shared scratch storage.

Prerequisites
-------------

The following prerequisites must have been met in order to follow this
guide:

-  `Alces compute environment deployed <http://alces-flight-appliance-docs.readthedocs.org/en/openstack/getting-started/deployment/openstack/deployment.html#deployment>`_
-  SSH access to the environment
-  Administrator account access (``alces`` user)
-  Access to OpenStack Horizon dashboard

Creating and attaching the volume
---------------------------------

The following section will detail the creation of a block storage volume, as well as attaching it to your cluster login node. 

From the OpenStack Horizon dashboard, perform the following steps: 

1.  Navigate to the Project -> Compute -> Volumes page
2.  Click the **Create Volume** button
3.  Enter an appropriate **Volume Name**, for example ``hpc1-sharedscratch``
4.  Enter a description if desired, this highlights to other users in your project what the volume is for
5.  **Volume Source**: Select ``No source, empty volume``
6.  **Type**: Select NFS, or if available - Cinder
7.  **Size**: Enter the size (in GB) of shared scratch storage space you wish to deploy
8.  **Availability Zone**: Select ``Any Availability Zone``
9.  Click the **Create Volume** button
10.  From the Volumes tab - use the **Actions** drop down box for your created volume, and select **Manage Attachments**
11.  Using the **Attach to Instance** dropdown box - select your clusters login node
12.  Click **Attach Volume**

The following configuration steps require SSH access to the login node of your compute environment. 

Configuring the volume as shared scratch storage
------------------------------------------------

Once you have logged on to the cluster login node as the administrator user - you can begin configuring the previously attached storage volume as cluster-wide shared storage. 

1.  Check the storage volume has correctly attached, this can be checked using ``sudo fdisk -l`` - typically it will be mounted at ``/dev/vdb`` - note down the mount point
2.  Format the attached storage volume

.. code:: bash
    sudo mkfs -t xfs /dev/vdb
    meta-data=/dev/vdb               isize=256    agcount=4, agsize=13107200 blks
             =                       sectsz=512   attr=2, projid32bit=1
             =                       crc=0        finobt=0
    data     =                       bsize=4096   blocks=52428800, imaxpct=25
             =                       sunit=0      swidth=0 blks
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
    log      =internal log           bsize=4096   blocks=25600, version=2
             =                       sectsz=512   sunit=0 blks, lazy-count=1
    realtime =none                   extsz=4096   blocks=0, rtextents=0

3.  Make a directory to mount the shared storage volume to, for example ``/sharedscratch``

.. code:: bash

    sudo mkdir /sharedscratch

4.  Modify the permissions of the directory to allow other users to read and write from the directory

.. code:: bash

    sudo chmod 777 /sharedscratch

5.  Permanently mount the volume to the login node, ensuring the mount persists through reboots. Add the following entry to the ``/etc/fstab`` file:

.. code:: bash

    /dev/vdb /sharedscratch xfs defaults 0 0

6.  Mount the entries in ``/etc/fstab``, this can be done using the ``sudo mount -a`` command
7.  Check the volume has correctly mounted

.. code:: bash

    [alces@login1(hpc1) ~]$ df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/vda1        40G  3.7G   37G  10% /
    devtmpfs        1.9G     0  1.9G   0% /dev
    tmpfs           1.9G     0  1.9G   0% /dev/shm
    tmpfs           1.9G   17M  1.9G   1% /run
    tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    tmpfs           380M     0  380M   0% /run/user/0
    tmpfs           380M     0  380M   0% /run/user/1000
    /dev/vdb        200G   33M  200G   1% /sharedscratch

8.  Add the mount to the login node list of NFS exports, add the following entry to the ``/etc/exports`` file

.. code:: bash

    /sharedscratch 10.75.0.0/255.255.0.0(rw,no_root_squash,no_subtree_check,async

9.  Export the mount using ``sudo exportfs -a``, then check the mount is available using ``showmount -e``: 

.. code:: bash

    [alces@login1(hpc1) ~]$ showmount -e
    Export list for login1:
    /opt/gridware/etc             10.75.0.4/32,10.75.0.6/32,10.75.0.5/32
    /home                         10.75.0.4/32,10.75.0.6/32,10.75.0.5/32
    /opt/gridware/depots/6665a7d5 10.75.0.4/32,10.75.0.6/32,10.75.0.5/32
    /sharedscratch                10.75.0.0/255.255.0.0

Configuring shared scratch on compute nodes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Once the above steps have been completed - you can now configure the compute nodes to mount and use the ``/sharedscratch`` directory

From the cluster login node, as the ``alces`` administrator user - perform the following commands: 

1.  Check that each of the compute nodes is able to see the previously created mount

.. code:: bash

    [alces@login1(hpc1) ~]$ pdsh -g nodes 'sudo showmount -e login1 | grep sharedscratch'
    node00: /sharedscratch                10.75.0.0/255.255.0.0
    node01: /sharedscratch                10.75.0.0/255.255.0.0
    node02: /sharedscratch                10.75.0.0/255.255.0.0

2.  Create the ``/sharedscratch`` (or your own preference) on each of the compute nodes, ready to mount the volume from the login node

.. code:: bash

    pdsh -g nodes 'sudo mkdir /sharedscratch'

3.  Add the external mount entry to each of the compute nodes ``/etc/fstab`` file

.. code:: bash

    [alces@login1(hpc1) ~]$ pdsh -g nodes 'echo "login1:/sharedscratch /sharedscratch nfs defaults 0 0" | sudo tee -a /etc/fstab'
    node01: login1:/sharedscratch /sharedscratch nfs defaults 0 0
    node00: login1:/sharedscratch /sharedscratch nfs defaults 0 0
    node02: login1:/sharedscratch /sharedscratch nfs defaults 0 0

4.  Mount the external volume to each of the compute nodes

.. code:: bash

    sudo pdsh -g nodes 'sudo mount -a'

5.  Verify each of the compute nodes has successfully mounted the volume

.. code:: bash

    [alces@login1(hpc1) ~]$ pdsh -g nodes 'df -h | grep sharedscratch'
    node01: login1:/sharedscratch                    200G   32M  200G   1% /sharedscratch
    node00: login1:/sharedscratch                    200G   32M  200G   1% /sharedscratch
    node02: login1:/sharedscratch                    200G   32M  200G   1% /sharedscratch

Your shared scratch volume is now ready for use with your workloads on both login node and cluster compute nodes. 

What's next?
------------

-  Add your shared scratch storage as a `system wide target using Alces Storage <http://alces-flight-appliance-docs.readthedocs.org/en/openstack/clusterware-storage/alces-storage-file-config.html#alces-storage-file-config>`_
