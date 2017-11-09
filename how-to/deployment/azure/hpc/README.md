Alces Flight on Azure
=====================

The following steps will help you to deploy and configure an Alces Flight Compute cluster on Azure public cloud. To get started, you will need the following:

* An SSH keypair
* An SSH client
* A Microsoft Azure account

The following resources are also used:

* Azure Resource Manager (ARM) template: <insert link here>

Creating an ARM template
------------------------

Once you have logged in to your Azure account, navigate to the *Templates* dashboard. From here - you will be able to create a new Alces Flight Compute template. 

* Click the **Add** button to begin creating a new template.
* Provide a name and description for your template in the **General** tab.
* Paste the contents of the ARM template into the **ARM Template** tab.
* Click **Add** to save the template, this will save your template for later use.

Deploying the Alces Flight Compute ARM template
-----------------------------------------------

Now that you have created an Alces Flight Compute ARM template - you can go ahead and deploy, the below steps cover deploying an ARM template:

* Use the option menu on the previously created Alces Flight ARM template and select **Deploy**. This will take you to the **Custom deployment** page.
* Select **Create new** in the **Resource group** option, then enter a name for your resource group. This can be the same, or different to the later defined **Cluster Name**.
* Select the region you wish to deploy your resources into.
* Enter your desired **Cluster Name** - this affects customization of your Alces Flight cluster.
* Enter your desired **Administrator Username**. This creates the admin user account, used for access to your Alces Flight cluster.
* Paste the contents of your SSH public keypair into the **Admin Public Key** field - this allows you to access the Login node using a combination of both the **Administrator Username** and your SSH private key.
* Select the desired **Compute Node Type**, this defines the number of CPU cores and memory available to each created compute node in your Alces Flight cluster.
* Enter the desired number of **Compute Nodes** in the **Compute Node Initial Count** field. This defines the number of compute nodes that will be initially created with your cluster. Throughout time - the cluster will grow and shrink based on usage.
* Select the desired **Login Node Type**, this defines the number of CPU cores and memory available on your Alces Flight Compute Login instance.
* Read over, and accept the terms and conditions.
* Click **Purchase** to begin deploying your Alces Flight Compute cluster.
