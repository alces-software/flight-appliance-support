#Using a seperate `/home` EBS volume for your compute environments
How to mount a seperate EBS volume as a user data for each of your deployed compute environments. This should be performed prior to shutting down a compute environment in order to preserve your home directory contents.  

##Prerequisites
* Alces Flight compute environment deployed

#Step 1 - configuring the initial volume

1. From the AWS EC2 console - navigate to the **Volumes** page
2. Click `Create Volume`, then choose: 
  * `Volume Type`: Select which type of volume you wish to use
  * `Size (GiB)`: Enter the size in GiB you wish to deploy. Note - any future deployed home directory volumes will need to be at least this size, so start with the smallest size required. 
  * `Availability Zone`: Choose from the selection of AZs
3. Click `Create` to start creating your new home directory storage volume

Once the volume has been marked `available` - you can attach it to your running Alces Flight login node: 

1. Right click your previously created volume and click `Attach Volume`
2. From the `Instance` selection box - choose your Alces Flight Compute login node
3. Choose a device name to attach it to - typically `/dev/xvdb` is fine
4. Click `Attach` to begin attaching the volume to your instance

Once the volume has attached - SSH to your Alces Flight login node, then begin initial configuration: 

1. Switch to the `root` user
2. Check the the volume has correctly attached using `fdisk -l`
3. Create a filesystem on the newly mounted volume: `mkfs.xfs /dev/xvdb`
4. Mount the volume to a temporary location - `/tmp` can be used for this, e.g. `mount /dev/xvdb /tmp`
5. Copy the contents including permissions of the `/home` directory to your new volume: `rsync -pav /home/* /tmp/.`
6. Unmount the volume: `umount /tmp`

From the AWS EC2 console, navigate to the **Volumes** page:

1. Right click your volume and select `Create Snapshot`
2. Choose a suitable name for your snapshot
3. Choose a suitable description for your snapshot
4. Click the `Create` button to create a snapshot of your home directory volume
5. Once the snapshot has completed - delete the home directory EBS volume from the **Volumes** page

#Step 2 - Reusing your home directory volume
This should be performed prior to any Alces ClusterWare tools performing `/home` NFS share exports. 

1. When creating your Alces Flight Compute login node - attach the previously created snapshot as an EBS volume
2. Once the login node has finished creating, SSH as the administrator user then switch to the `root` user
3. Check the volume has correctly mounted using `fdisk -l`
4. Mount the volume to the `/home` directory: `mount /dev/xvdb /home`
5. Switch to the administrator user, e.g. `alces` - and you should see the contents of your previous clusters' home directory: 

```bash
[alces@login1(hola) ~]$ ls
myjob.1.output  clusterware-setup-sshkey.log  job-scripts 
```

#Increasing the size of the home directory
When attaching the home directory snapshot to your Alces Flight Compute login node - you may optionally choose a larger size than the snapshot size. The filesystem will not automatically grow, manual intervention is required in order to use the newly acquired space.

From your Alces Flight Compute login node with a larger disk: 

1. Switch to the `root` user
2. Grow the attached disk to its maximum supported size using `xfs_growfs -d /dev/xvdb`
3. Your filesystem should now show the increased size: 

```bash
[alces@login1(alces-cluster) ~]$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      8.0G  3.6G  4.5G  45% /
devtmpfs        3.9G     0  3.9G   0% /dev
tmpfs           3.7G     0  3.7G   0% /dev/shm
tmpfs           3.7G   17M  3.7G   1% /run
tmpfs           3.7G     0  3.7G   0% /sys/fs/cgroup
tmpfs           757M     0  757M   0% /run/user/1000
/dev/xvdb        50G   53M   47G   1% /home 
```
