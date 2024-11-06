---
layout: post
title: Use snapshot to backup Azure file with Kasten
description: With csi snapshots backing up with Kasten is very simple. Since april 2024 the azure file csi driver now support snapshot (for SMB volume) 
   and is shipped with AKS. Let's see how easy it is now to backup an azure file volume in Kubernetes.
date: 2024-11-06 00:00:35 +0300
author: michaelcourcy
image: '/images/posts/2024-11-06-use-snapshot-to-backup-azure-file/azure-files-backed-up.png'
image_caption: 'Simple workflow for backing up azure file'
tags: [Azure file, Crash consistency, Backup, Kasten, Kubernetes, Snapshot, Azure]
featured:
---

# What is crash consistency ? And why it matters ? 

Crash consistency means consistent with the filesystem before the crash. When a backup is crash consistent it's like all the files where captured at the same time.


Crash consistency is very important but you understand this importance when you restore not when you backup. If you do not do crash consistent backup 
then the backup contains files that are captured at different times and when you restore the application may not be able to recover at restart. 
Or it may be able to restart and seems to recover but actually restart with an unconsistent state.

# How do you obtain crash consistency 

There is two way to obtain crash consistency :
- You quiesce any IO operation on the filesystem during the backup 
- You take a volume snapshot by calling the storage provider API (the storage provider then guarantee the crash consistency)

If snapshot is not available (as it was the case with Azure file until recently) you could quiesce the workload by using a Kasten blueprint. That's exactly what 
the [mogondb blueprint example](https://docs.kasten.io/latest/kanister/mongodb/install_app_cons.html) do. But this requires a specific blueprint based on the nature of the workload.

If you want to do a volume snapshot with kasten, either your [in tree](https://kubernetes.io/blog/2022/09/26/storage-in-tree-to-csi-migration-status-update-1.25/) storage is supported by Kasten or the [CSI storage driver](https://github.com/container-storage-interface/spec/blob/master/spec.md#objective) supports the snapshot capabilities and kasten works with the storage interface in a generic manner.

Azure file csi was a typical example of a csi driver that did not have snsapshot capabilities. So in this case you either implemented a blueprint or you 
did a trade off : better having a non crash consistent backup than no backup at all, which is a also a sensible choice if you know what you're doing.

# Now Azure csi file driver support complete snapshot workflow 

From [v1.30.2](https://github.com/kubernetes-sigs/azurefile-csi-driver/releases/tag/v1.30.2) (april 2024), the restoration of an SMB file share snapshot is now supported by the azure file CSI driver. 

Before v1.30.2 the snapshot was possible but the restore has to be done through the Azure portal GUI and no API were available. This was a blocker for Kasten 
because Kasten could do a local snapshot but was blocked to do an export as export needed a temporary restore of the snapshot in the Kasten namespace.

# Let's test it !

## Install Kasten on this cluster

My AKS cluster 
```
az version
{
  "azure-cli": "2.62.0",
  "azure-cli-core": "2.62.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
kubectl version                      
Client Version: v1.30.3
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.29.9
az aks show --resource-group rg-cluster-mcourcy2-tf --name aks-cluster-mcourcy2-tf --query kubernetesVersion --output tsv
1.29
```


Install kasten on the cluster and do the minimal configuration
```
aks get-credentials --resource-group ... --name ...
helm repo add kasten https://charts.kasten.io/
helm repo update
kubectl create ns kasten-io 
helm install k10 kasten/k10 -n kasten-io
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/snapshot/volumesnapshotclass-azurefile.yaml
kubectl annotate volumesnapshotclass csi-azurefile-vsc k10.kasten.io/is-snapshot-class=true
```
 
Connect to the kasten instance
```
kubectl --namespace kasten-io port-forward service/gateway 8080:80
```

The Kasten dashboard will be available at: `http://127.0.0.1:8080/k10/#/`

You should create also a [location profile](https://docs.kasten.io/7.0.12/usage/configuration.html) on your cluster to experiment export. 

## Create a small app on the cluster in eastus

Let's create a minimal application that will generate some data regulary following this 
[tutorial](https://github.com/michaelcourcy/basic-app)  with those values 
```
STORAGE_CLASS=azurefile
SIZE="2Gi"
IMAGE=docker.io/busybox:latest
```

After following the installation in the tutorial check that all is running and your pvc is an azurefile pvc 
```
kubectl exec -n basic-app deploy/basic-app-deployment -- cat /data/date.txt
Wed Nov  6 10:14:53 UTC 2024
Wed Nov  6 10:15:03 UTC 2024
Wed Nov  6 10:15:13 UTC 2024
Wed Nov  6 10:15:23 UTC 2024
Wed Nov  6 10:15:33 UTC 2024
Wed Nov  6 10:15:43 UTC 2024
Wed Nov  6 10:15:53 UTC 2024
Wed Nov  6 10:16:03 UTC 2024
Wed Nov  6 10:16:13 UTC 2024

kubectl get pvc -n basic-app
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
basic-app-pvc   Bound    pvc-f8069b82-3b7f-4b8a-9c9f-12d2a9a77a29   2Gi        RWO            azurefile      <unset>                 2m2s
```

## Create a policy and launch it
Let's use the kasten GUI to create an on demand policy with the location profile to export the backup. 

![Create and launch the policy](../images/posts/2024-11-06-use-snapshot-to-backup-azure-file/create-and-launch-policy.png)

## We need to fix an authorization issue 
I discovered that the policy succeed at backup but was stuck at the export phase 
![policy stuck at export](../images/posts/2024-11-06-use-snapshot-to-backup-azure-file/policy-stuck-at-export.png)

and when checking the pod in kasten-io namespace I could see that copy-vol pod was stuck on containerCreating state 
```
NAME                                     READY   STATUS              RESTARTS      AGE
aggregatedapis-svc-75689d745c-gs9rs      1/1     Running             1 (41h ago)   41h
auth-svc-77f98fbcc7-9nqgp                1/1     Running             0             41h
catalog-svc-85f4d9478-j8f9l              2/2     Running             0             41h
controllermanager-svc-778ffd8c45-gsqhg   1/1     Running             0             41h
copy-vol-data-24hnd                      0/1     ContainerCreating   0             65s
crypto-svc-5fc46bc587-m6bk9              4/4     Running             0             41h
dashboardbff-svc-7c767cf68-rhsdj         2/2     Running             0             41h
data-mover-svc-8w22n                     1/1     Running             0             71s
executor-svc-cc7bc6dfd-bvms6             1/1     Running             0             41h
executor-svc-cc7bc6dfd-c94bz             1/1     Running             0             41h
executor-svc-cc7bc6dfd-gqpvt             1/1     Running             0             41h
frontend-svc-785d56b474-grs6j            1/1     Running             0             41h
gateway-84f5b4c565-cqcdv                 1/1     Running             0             41h
jobs-svc-77cdbd44b7-6th5r                1/1     Running             0             41h
k10-grafana-6c59579d58-kvxs7             1/1     Running             0             41h
kanister-svc-59b4897c75-gb5ms            1/1     Running             0             41h
logging-svc-7ff9bcf495-dhppk             1/1     Running             0             41h
metering-svc-8bbb869f8-gvfsb             1/1     Running             0             41h
prometheus-server-8654c988b5-gvlf8       2/2     Running             0             41h
state-svc-8b757496f-4zzh4                2/2     Running             0             41h
```

When I describe it 
```
  Warning  FailedMount       51s (x8 over 116s)  kubelet            MountVolume.MountDevice failed for volume "pvc-855a0b4d-049e-450f-8bad-afcc0540fb3b" : rpc error: code = InvalidArgument desc = GetAccountInfo(MC_rg-cluster-mcourcy2-tf_aks-cluster-mcourcy2-tf_westus#ft203c90415fd4e9187case#pvc-855a0b4d-049e-450f-8bad-afcc0540fb3b###kasten-io) failed with error: Retriable: false, RetryAfter: 0s, HTTPStatusCode: 403, RawError: {"error":{"code":"AuthorizationFailed","message":"The client '338f35ef-af1b-4069-8a0f-9e722f33cs2d' with object id '338f35ef-af1b-4069-8a0f-9e722f33cs2d' does not have authorization to perform action 'Microsoft.Storage/storageAccounts/listKeys/action' over scope '/subscriptions/662b52f9-b122-4635-9e4c-ce4119cb09e4/resourceGroups/MC_rg-cluster-mcourcy2-tf_aks-cluster-mcourcy2-tf_westus/providers/Microsoft.Storage/storageAccounts/ft203c90415fd4e9187case' or the scope is invalid. If access was recently granted, please refresh your credentials."}}
```

I noticed that the managed identity that mount the smb volume on the nodes did not have enough authorization 
![find the client](../images/posts/2024-11-06-use-snapshot-to-backup-azure-file/find-the-client.png)
And it has a name based on my aks resource group aks-cluster-mcourcy2-tf-agentpool 


I fixed it by adding the role to this identity on the storage account 
```
az role assignment create \
   --assignee 338f35ef-af1b-4069-8a0f-9e722f33cs2d \
   --role "Storage Account Key Operator Service Role" \
   --scope /subscriptions/662b52f9-b122-4635-9e4c-ce4119cb09e4/resourceGroups/MC_rg-cluster-mcourcy2-tf_aks-cluster-mcourcy2-tf_westus/providers/Microsoft.Storage/storageAccounts/ft203c90415fd4e9187case
```

Then I deleted the copy-vol pod and kasten retried this time with success
![Policy succeeded](../images/posts/2024-11-06-use-snapshot-to-backup-azure-file/policy-succeeded.png)


# Testing restore 

Restoring from the local restore point does not work and I was not able to troubleshoot it yet. I get this error message when I describe the 
restored pvc in the kasten-io namespace that remain in pending state. 
```
kubectl describe pvc k10restore-ae58ea53-eb2c-4fa9-a9b1-23f162e6a4a3 -n kasten-io
....
INFO: azcopy 10.26.0: A newer version 10.27.0 is available to download

INFO: Login with identity succeeded.
INFO: Authenticating to destination using Azure AD
INFO: Authenticating to source using Azure AD
INFO: Failed to create one or more destination container(s). Your transfers may still succeed if the container already exists.
INFO: Any empty folders will be processed, because source and destination both support folders
INFO: Failed to scan directory/file . Logging errors in scanning logs.

failed to perform copy command due to error: cannot start job due to error: GET https://ft203c90415fd4e9187case.file.core.windows.net/pvc-f8069b82-3b7f-4b8a-9c9f-12d2a9a77a29/
--------------------------------------------------------------------------------
RESPONSE 404: 404 The specified share does not exist.
ERROR CODE: ShareNotFound
--------------------------------------------------------------------------------
<?xml version="1.0" encoding="utf-8"?><Error><Code>ShareNotFound</Code><Message>The specified share does not exist.
RequestId:09965ca5-e01a-0077-7c3e-302386000000
Time:2024-11-06T11:23:32.3538456Z</Message></Error>
--------------------------------------------------------------------------------
```
I'm still working on it.

However restoring from the remote restore point is possible.

When you restore you'll see a break in the dates command which map with the backup date and the restart of the pod.
```
Wed Nov  6 10:34:25 UTC 2024
Wed Nov  6 10:34:35 UTC 2024
Wed Nov  6 10:34:45 UTC 2024
Wed Nov  6 10:34:55 UTC 2024
Wed Nov  6 10:35:05 UTC 2024
Wed Nov  6 10:35:15 UTC 2024
Wed Nov  6 13:27:34 UTC 2024 <-------------
Wed Nov  6 13:27:44 UTC 2024
Wed Nov  6 13:27:54 UTC 2024
Wed Nov  6 13:28:05 UTC 2024
Wed Nov  6 13:28:15 UTC 2024
Wed Nov  6 13:28:25 UTC 2024
Wed Nov  6 13:28:35 UTC 2024
```

Which is consistent with the time of my restorepoint. 10:35 UTC or 11:35 french time 
![Restore point](../images/posts/2024-11-06-use-snapshot-to-backup-azure-file/retorepoint.png)


# Conclusion

This is a very good news for any AKS administrator to know that they don't need anymore to use the Kasten GVS configuration for azure file and they will even have
crash consistent backup. This updated version of the driver is not yet in the azure file csi driver shipped with openshift but will be soon hopefully.