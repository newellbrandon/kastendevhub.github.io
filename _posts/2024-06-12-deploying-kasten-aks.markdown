---
author: mattslotten
date: 2024-06-07 08:21:37 +0100
description: "In this post, we deploy Kasten on Azure Kubernetes Service with Azure Container Storage"
featured: false
image: "/images/posts/2024-06-12-deploying-kasten-aks/header_image.png"
image_caption: ""
layout: post
published: true
tags: [azure, azure container storage, marketplace]
title: "Azure, Kasten, and Automation, best friends forever (BFF)"
---

# Overview

With the release of Veeam Kasten v7, we've introduced some pretty slick new enterprise and security features, capabilities, and optimizations. To learn more, definitely check out <a href="https://www.veeam.com/blog/kasten-veeam-7-0.html" target="_blank"> the official release blog</a> written by our dear leader, Gaurav Rishi.

One such capability is to purchase and <a href="https://azuremarketplace.microsoft.com/en-us/marketplace/apps/veeamsoftware.veeam-kasten-az?tab=Overview" target="_blank">deploy Kasten directly from the Azure Container Marketplace</a> to an existing Azure Kubernetes Cluster (AKS).

It's pretty nifty and I'm quite proud of this capability (and the engineers who implemented it, as honestly they did most of the leg work), as it was one of my first "soup to nuts" FEATs I had the honor of leading - look ma, I work in Product now!

{: .alert-info }
Note there's a little joke for the Kasten peeps and users in the title. BFF in the Kasten world actually stands for Backend for the Front End, so really the Front End's BFF _is_ the BFF. It's recursion! JOKES!

# The Details

And while it absolutely helps remove some of the friction around deploying Kasten to AKS (and makes it easier for us to collect those **ca$h monie$** for licensing), I figured I could help elevate this one step further and help automate the deployment of the AKS cluster itself, complete with Azure Container Storage and nginx ingress, all ready to go for installing Kasten, whether via the ClickOps offered via the Azure Marketplace or via helm.

<img src="./images/posts/2024-06-12-deploying-kasten-aks/aks_kasten_logical.png" alt="Logical Diagram of Kasten and AKS" />

Really, I just baked together a bash script to capture relevant details and deploy a cluster for my demo purposes. Often times I have to stand up and tear down clusters quickly for demo purposes and I got tired of copying any pasting from my notes, so I assembled a quick and dirty bash script to spare my precious fingers from having to click or type... gotta save those calories! 

I've made a few assumptions and this won't work for you if you have additional requirements, or wish to deploy anything other than a basic 3-node AKS cluster with Azure Container Storage backed by AzureDisk. But the script can be easily modified for your needs and at the very least can be used to help bootstrap something more elegant.

# The Script

So what does the script actually do?

It prompts for:

- Your Azure subscription ID
- An Azure region to which you wish to deploy [Optional, default is eastus]
- A name for the AKS cluster
- A name for the AKS Resource Group [Optional, default is *AKS cluster name*_group]
- A DNS name for the cluster ingress

Worth noting that you'll need the above information and once created, you'll need to create an entry in DNS (e.g. Azure DNS record) that points to the public IP address of the `ingress-nginx-controller` service. I could probably script this last part, but maybe that'll be a different day.

Once it has all the bits it needs, it goes off and deploys an AKS cluster in your Azure subscription in the region of your choosing, configures Azure Container Storage with a Storage Pool backed by AzureDisk, creates a VolumeSnapshotClass with the required `k10.kasten.io/is-snapshot-class: "true"` annotation, deploys an nginx ingress with the configured DNS name, and leaves you with a friendly AKS cluster on which you can now deploy Kasten, either via the <a href="https://azuremarketplace.microsoft.com/en-us/marketplace/apps/veeamsoftware.veeam-kasten-az?tab=Overview" target="_blank">Azure marketplace integration</a> or via helm.

{: .alert-warning }
Worth mentioning that any scripts, resources, etc provided on this site are NOT officially supported by Veeam/Kasten/myself/etc.  So before deploying, probably worth actually reading the short script to make sure it's doing everything you want it to do and you have the right permission within your Azure subscription to perform the various tasks.  Also note that there is no error checking/etc in the script, so if after throwing the spaghetti against the wall it doesn't stick, you may have to go clean up the provisioned resources manually.

Enough already, where's the script!? Alright, <a href="./resources/scripts/deploy_aks_cluster.sh" target="_blank">here's a link</a>. Or if you just want to pull it down to your local machine:

```
wget https://veeamkasten.dev/resources/scripts/deploy_aks_cluster.sh
chmod +x ./deploy_aks_cluster.sh
```

Alternatively, if you just want to the az aks command to deploy the cluster:

```
az aks create -n <clusterName> -g <resourceGroupName> --node-vm-size Standard_D4s_v5 --node-count 3 --enable-azure-container-storage azureDisk --os-sku AzureLinux
```

# In Summary
Kasten works great on Azure Kubernetes Service, or Azure Red Hat OpenShift (ARO) for that matter, and can leverage the full capabilities of AKS, including Azure Linux Container Host, Azure Container Storage (ACS), Azure Blob with Immutability for secured backup (also a v7 capability), and Azure Sentinel for Security information and event management (SIEM) (yet ANOTHER v7 capability!).




