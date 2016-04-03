#Adding an NFS server to your compute environment
How to add an NFS server to your compute environment using the CloudFormation console.

##Prerequisites

- Alces Flight compute environment deployed
- `nfs.json` CloudFormation template saved to local machine

#Deployment through CloudFormation console
The `nfs.json` CloudFormation template should be used to attach an NFS server to your environment. Navigate to the CloudFormation console to begin creating your NFS server.

1. Click **Create Stack**
2. Click **Upload a template to Amazon S3**
3. Choose the previously saved `nfs.json` CloudFormation template
4. Click **Next**
5. Enter your desired `Stack name` - this should typically be your cluster name + a suitable identifier, e.g. `mycluster-storage`
6. Enter your previously deployed cluster `CLUSTERNAME` - for example `mycluster`
7. Select your AWS keypair, this is used for administrator access to the NFS server
8. Enter your previously deployed cluster login node internal IP - this is used to register your NFS server with the environment; for example `10.75.0.10`
9. *Optional* Enter the name of your clusters placement group; this will greatly increase the performance of your NFS server when using Medium or above
10. Select the security group of your existing compute environment
11. Enter the spot price you wish to pay per hour in USD for your instance. If you do not wish to use spot - please enter `None`
13. Select the `STORAGETYPE` - this defines the number of CPU cores and memory and storage available to the NFS server.
14. Select the subnet ID of your existing compute environment
15. Enter the administrator username used in your existing cluster, for example `alces`
16. Click **Next**
17. On the **Tags** page, click the **Next** button
18. On the **Review** page, click the **Create** button to deploy your NFS server and storage

Once the stack deployment has finished, your NFS server will automatically register in your compute environment. From your cluster login node - as the administrator user, SSH to `storage1` to start using your NFS server.

##Storage setup
Once logged on to your storage server, the following steps should be performed to appropriately configure your storage server with your environment.

As the administrator user - run the following command to set up your environment:

```bash
curl -ssL https://git.io/vVGp3 | /bin/bash
```

The above command will correctly format your disk, as well as share the volume to nodes within your environment.

SSH to either your cluster login node, or a cluster compute node - and check that the `storage1:/mnt/data` volume is available:

```bash
[alces-cluster@login1(hpc1) ~]$ df -h
Filesystem          Size  Used Avail Use% Mounted on
/dev/xvda1          500G  3.8G  497G   1% /
devtmpfs            3.9G     0  3.9G   0% /dev
tmpfs               3.7G     0  3.7G   0% /dev/shm
tmpfs               3.7G   17M  3.7G   1% /run
tmpfs               3.7G     0  3.7G   0% /sys/fs/cgroup
storage1:/mnt/data  4.9T   23G  4.9T   1% /mnt/data
tmpfs               757M     0  757M   0% /run/user/0
tmpfs               757M     0  757M   0% /run/user/1000
```
