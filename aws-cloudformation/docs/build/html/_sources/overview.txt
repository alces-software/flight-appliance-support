.. _overview:

Overview
########

The Alces Flight appliances are designed to simplify deployment of various compute environments using public and private Cloud providers including AWS and OpenStack. The Flight appliances lower the barrier to entry of Cloud computing, as well as reducing overall cost by serving a pre-configured environment to you in just minutes.  

Available Appliances
--------------------
The currently available Alces Flight appliances include: 

* `Alces Flight Compute Appliance`_
* `Alces Flight Storage Access Appliance`_
* Alces Flight Application Manager Appliance
* Alces Flight Galaxy Appliance

Alces Flight Compute Appliance
******************************
The Alces Flight Compute appliance provides two primary roles -- a cluster master node; hosting the primary cluster services, as well as compute node roles. The Alces Compute image is configured via user-data, which informs the Alces Compute image which role to take on. 

The Compute image has been designed to simplify the deployment of HPC compute environments in the Cloud, significantly reducing the time-to-research. 

The Alces Compute image providers researchers with powerful tools to get started with their research in the Cloud, including: 

* Applications on-demand

The Alces HPC compute image contains tools to provide on-demand applications, with over 750 different applications libraries and compilers available through the *modules* environment together with Alces Gridware. 

* Dynamic self-configuring HPC scheduler

The Alces HPC compute image self-configures, automatically creating a workload-ready HPC compute environment. The Alces HPC compute image is capable of deploying both scheduler master nodes, as well as worker nodes - with scheduler configurations included. 

* Familiar environment

The Alces HPC compute image is deployed in a traditional HPC compute environment architecture, with cluster master nodes running the job scheduler - as well as dedicated compute nodes, shared directories and more. 

Alces Flight Storage Access Appliance
*************************************
The Alces Flight Storage Access appliance provides users with a means to manage uploading, downloading and manipulating files in their cluster POSIX storage and object stores via their web browser. 

The Alces Flight Storage Access appliance allows researchers to seamlessly interact with both POSIX filesystems and object storage in a consistent manner. Many different storage configurations can be added to the Storage Manager appliance, allowing researchers to couple storage from multiple Cloud environments together in one simple but powerful interface. 
