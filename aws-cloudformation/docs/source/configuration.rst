.. _configuration:

Configuration
#############

The following section details the initial configuration options available from user-data when deploying Alces compute environments in the Cloud.

HPC environments
----------------
There are two types of Alces Flight Compute Appliance deployments available: 

* **Cluster master node**: Cluster scheduler host, shared NFS server, user login node
* **Cluster compute node**: Scheduler execution host

Each type requires user-data to be included upon deployment in order to correctly configure the image - examples of both master node and compute nodes are shown below: 

Cluster master node
*******************
.. code-block:: yaml

    #cloud-config
    hostname: login1
    fqdn: login1.clusterware.alces.network
    write_files:
    - content: |
        cluster:
          uuid: '7b4249e8-637a-11e5-a343-7831c1c0e63c'
          token: '8R0c6lyMG1pJGP/wzg8dHA=='
          name: 'clusterware'
          role: 'master'
          tags:
            scheduler_roles: ':master:'
          quorum: 3
          gridware:
            depots:
            - name: benchmark
              url: https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/depots/benchmark
        instance:
          users:
          - username: alces-cluster
            uid: 509
            group: alces-cluster
            gid: 509
            groups:
              - gridware
              - admins:388
            ssh_public_key: |
              ssh-rsa 1234 user
      owner: root:root
      path: /opt/clusterware/etc/config.yml
      permissions: '0640'
