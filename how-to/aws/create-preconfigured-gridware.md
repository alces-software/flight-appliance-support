# How to create a preconfigured Gridware volume

## Overview

This how to guide outlines the steps required to create an EBS snapshot containing a curated set of applications that can be used with an Alces Flight Compute cluster.

## Set up

### Set up your application volume snapshot

1. Launch the Alces Flight Compute AMI as a single instance (`t2.large` recommended).  At Step 4, you should "Add a new volume" and configure it appropriately for size.
2. Once launched, SSH into the instance and use `sudo` to become the superuser.
3. Set up the volume, e.g.:

	```
	[root@ip-172-31-16-254(unconfigured) alces]# fdisk /dev/xvdb
	Welcome to fdisk (util-linux 2.23.2).
	
	Changes will remain in memory only, until you decide to write them.
	Be careful before using the write command.
	
	Device does not contain a recognized partition table
	Building a new DOS disklabel with disk identifier 0xeeeaef95.
	
	Command (m for help): n
	Partition type:
	   p   primary (0 primary, 0 extended, 4 free)
	   e   extended
	Select (default p): p
	Partition number (1-4, default 1):
	First sector (2048-16777215, default 2048):
	Using default value 2048
	Last sector, +sectors or +size{K,M,G} (2048-16777215, default 16777215):
	Using default value 16777215
	Partition 1 of type Linux and of size 8 GiB is set
	
	Command (m for help): w
	The partition table has been altered!
	
	Calling ioctl() to re-read partition table.
	Syncing disks.
	```

4. Format the new partition:

    ```
    [root@ip-172-31-16-254(unconfigured) alces]# mkfs.ext4 /dev/xvdb1
	mke2fs 1.42.9 (28-Dec-2013)
	Filesystem label=
	OS type: Linux
	Block size=4096 (log=2)
	Fragment size=4096 (log=2)
	Stride=0 blocks, Stripe width=0 blocks
	524288 inodes, 2096896 blocks
	104844 blocks (5.00%) reserved for the super user
	First data block=0
	Maximum filesystem blocks=2147483648
	64 block groups
	32768 blocks per group, 32768 fragments per group
	8192 inodes per group
	Superblock backups stored on blocks:
		32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632
	
	Allocating group tables: done
	Writing inode tables: done
	Creating journal (32768 blocks): done
	Writing superblocks and filesystem accounting information: done
    ```

5. Mount the partition and move the existing Gridware tree:

	```
	[root@ip-172-31-16-254(unconfigured) alces]# mount /dev/xvdb1 /mnt
	[root@ip-172-31-16-254(unconfigured) alces]# mv /opt/gridware/* /mnt
	[root@ip-172-31-16-254(unconfigured) alces]# umount /mnt
	[root@ip-172-31-16-254(unconfigured) alces]# mount /dev/xvdb1 /opt/gridware
	```
	
6. Create a new Gridware depot to host your software collection:

	```
	[root@ip-172-31-16-254(unconfigured) alces]# al gr depot init site

	 > Initializing depot: site
	      Initialize ... OK
	```

7. Proceed with application installation into the newly created site depot:

	```
	[root@ip-172-31-16-254(unconfigured) alces]# al gr inst -d site apps/R/3.3.0
	Preparing to install main/apps/R/3.3.0

	WARNING: Package requires the installation of the following:
	  main/apps/cmake/3.5.2, main/libs/blas/3.6.0, main/libs/lapack/3.5.0
	
	Install these dependencies first?
	
	Proceed (Y/N)? y
    [...]
	Installing main/apps/R/3.3.0
	Importing apps-R-3.3.0-el7.tar.gz
	
	 > Fetching archive
	        Download ... OK
	
	 > Preparing import
	         Extract ... OK
	          Verify ... OK
	
	 > Processing apps/R/3.3.0/gcc-4.8.5+lapack-3.5.0+blas-3.6.0
	       Preparing ... OK
	       Importing ... OK
	     Permissions ... OK
	
	 > Finalizing import
	          Update ... OK
	    Dependencies ... OK
	
	Installation complete.    
	```

### Create the snapshot

1. Stop the instance (NB. you can terminate the instance at this point if the volume was not marked as "Delete on Termination", otherwise you can terminate after creating the snapshot below.)
2. In the EC2 console, locate the volume you created and create a snapshot from it.

You now have a snapshot that can be used to provide preinstalled Gridware to future Alces Flight Compute instances.

## Launching

### Manual launch and configuration

1. Launch the Alces Flight Compute AMI as a single instance.
2. Access the instance over SSH.
3. Add your AWS credentials to the environment:

	```
	export AWS_ACCESS_KEY_ID="account"
	export AWS_SECRET_ACCESS_KEY="secret"
	```

4. Create a volume from the snapshot you created, noting that you're matching the availability zone of the launched instance. e.g.:

	```	
    aws ec2 create-volume --snapshot-id snap-eebbc8c5 --availability-zone eu-west-1a --region eu-west-1
    ```
    
5. Attach the volume to the instance. e.g.:

	```
	aws ec2 attach-volume --volume-id vol-7452e9b1 --instance-id i-97c3c91f --device xvdb --region eu-west-1
	```
	
6. Mount the volume to `/opt/gridware`:

	```
	mount /dev/xvdb1 /opt/gridware
	```

7. Add the `site` depot to the global modules path (only required on the master node):

	```
	echo '/opt/gridware/site/$cw_DIST/etc/modules' >> /opt/clusterware/etc/gridware/global/modulespath
	```	

8. Proceed with manual configuration as outlined in the [Alces Flight documentation](http://docs.alces-flight.com/en/stable/launch-aws/manual-launch.html).


### Launching an Alces Flight Compute cluster with an application volume

1. Download a CloudFormation template for Alces Flight Compute.
2. Modify the template to create a volume from your snapshot.  Refer to the CloudFormation documentation on how to [create volumes](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-ebs-volume.html), e.g.:
	
		```
		"FlightApplicationVolume": {
		    "Type": "AWS::EC2::Volume",
	            "DependsOn": "FlightSubnet",
	            "Properties": {
					"AvailabilityZone": { "Fn::GetAtt" : [ "FlightSubnet", "AvailabilityZone" ] },
					"SnapshotId": "snap-c81027e3"
	            }
		},
		```

3. Modify the template to depend on and attach the created volume to the `FlightLogin` instance. Note that `xvda` through `xvdc` are already defined as `BlockDeviceMappings` so your volume should be configured as `xvdd` in the `Volumes` property. e.g.

	* Instance:
	
		```
		"FlightLogin": {
    	    "Type": "AWS::EC2::Instance",
			"DependsOn": ["FlightGWAttach", "FlightApplicationVolume"],
            "Properties": {
				"Volumes": [
		    		{
				        "Device": "xvdd",
		    		    "VolumeId": { "Ref": "FlightApplicationVolume" }
				    }
				],
		```
	
4. Create a customization hook to mount the Gridware volume at `configure` time and upload it to an S3 bucket for [Alces Flight customizations](http://docs.alces-flight.com/en/stable/customisation/customisation.htm).  The hook may be as simple as:

	```
	#!/bin/bash
	if [ "$2" == "master" ]; then
  	  mount /dev/xvdd1 /opt/gridware
	  echo '/opt/gridware/site/$cw_DIST/etc/modules' >> /opt/clusterware/etc/gridware/global/modulespath
	fi
	```

4. Use CloudFormation to launch your template, if you've not placed it in the default profile, supply the name you have given your customization profile in the `FlightCustomProfiles` field.
