#Creating a Lustre cluster for use with an Alces Flight compute environment
How to create a Lustre parallel filesystem using AWS for use with a pre-existing Alces Flight Compute environment to provide scratch storage to compute nodes.

Upon completion, the following guide will deploy a Lustre cluster with: 

- 1 x Lustre MDS/MGS with SSDs
- 1 x Lustre OSS with up to 42TB usable storage

Additional OSS can be deployed with ease, allowing you to easily expand your Lustre cluster.

##Prerequisites
- Alces Flight compute environment deployed
- Appropriate IAM permissions or root account

#Lustre cluster deployment
Use the `lustre.json` CloudFormation template included to launch the Lustre cluster into your existing compute environment. 

#Configuration
##MDS configuration
SSH to the MDS node using the `centos` administrator user, together with the public IP address of the MDS node. 

Once on the `mds1` node - switch to the `root` user to begin configuration. Run the following command to initiate configuration: 

```bash
curl -ssL https://git.io/vV571 | /bin/bash
```

##OSS configuration
From your Flight compute environments login node - SSH to the `oss1` machine. Once on the `oss1` node - switch to the `root` user to begin configuration. Run the following command to initiate configuration: 

```bash
export ossnum=0; curl -ssL https://git.io/vV7xi | /bin/bash
```

For each additional OSS deployed, increment the `ossnum` variable by 1. 

##Client configuration
From your Flight compute environments login node - perform client configuration, allowing each of the nodes in your environment to mount the Lustre filesystem: 

This should be performed as the administrator user, e.g. `alces`: 

```bash
curl -ssL https://git.io/vV5di | /bin/bash
```

Each of your nodes will now have the Lustre filesystem mounted at `/mnt/data`. 

#Guideline performance figures
The following figures are simply a guideline to show the possible performance of a Lustre cluster with Flight Compute using AWS.

##1 x MDS/1 x OSS (10GbE enabled)
The following setup was used to achieve the below figures: 

- Single MDS/MGT node (`i2.xlarge` with 2 x SSDs)
- Single OSS with 24 x instance store disks in a single logical volume (`d2.8xlarge`)
- Three compute node clients with the Lustre filesystem mounted and 10GbE enabled (`c4.8xlarge`)

- Three clients writing to a single OST: 
  - 1.1GB/sec write total throughput
  - 367MB/sec write per client

- Single client writing to a single OST:
  - 1.05GB/sec write total throughput


