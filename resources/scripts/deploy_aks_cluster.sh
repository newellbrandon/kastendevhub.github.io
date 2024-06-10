#!/bin/bash

read -e -p 'Azure Subscription ID: ' azSubID
read -e -p 'Azure Region to which to deploy (default is eastus): ' location
location=${location:-eastus}
read -e -p 'AKS Cluster Name: ' clusterName
read -e -p "Resource Group Name (default is ${clusterName}_group): " rgName
rgName=${name:-${clusterName}"_group"}
read -e -p 'Ingress DNS name: ' ingressDNS

printf "\r\nInputs Specified:\r\n"
echo "#########################################"
echo "Azure Subscription ID: $azSubID"
echo "Location: $location"
echo "AKS Cluster Name: $clusterName"
echo "Resource Group Name: $rgName"
echo "Ingress DNS name: $ingressDNS"
echo "#########################################"
read -e -p "Ready to deploy? " choice

[[ "$choice" == [Yy]* ]] && printf "\r\n## Strap in, here we go! ##\r\n" || printf "\r\n## Mission Aborted ##\r\n"; exit

#defaults
ingressNS='ingress-nginx'


# Connect to AZ subscription
az account set --subscription $azSubID

#Create resource group
nohup az group create --name $rgName --location $location

wait

echo "AZ Group $rgName created in $location. Creating AKS cluster with Azure Container Storage. This may take some time"

#Create cluster
nohup az aks create -n $clusterName -g $rgName --node-vm-size Standard_D4s_v5 --node-count 3 --enable-azure-container-storage azureDisk

wait

echo "AKS Cluster $clusterName Created! Grabbing K8s cluster credentials"

#Download cluster credentials
nohup az aks get-credentials --resource-group $rgName --name $clusterName --overwrite-existing

wait

echo "AKS cluster credentials stored. Creating storage pool, setting default storage class, and creating VolumeSnapshotClass"

#Create an ACS StoragePool
nohup cat <<EOF | kubectl apply -f -
apiVersion: containerstorage.azure.com/v1alpha1
kind: StoragePool
metadata:
  name: azuredisk
  namespace: acstor
spec:
  poolType:
    azureDisk: {}
  resources:
    requests: {"storage": 1Ti}
EOF

wait

nohup kubectl patch storageclass acstor-azuredisk -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
nohup cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-acstor-vsc
  annotations:
    k10.kasten.io/is-snapshot-class: "true"
driver: containerstorage.csi.azure.com
deletionPolicy: Delete
parameters:
  incremental: "true"
EOF

wait

echo "Storage assets created, deploying Nginx Ingress using DNS name $ingressDNS. This may take a bit of time."

nohup helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
nohup helm repo update

wait
nohup helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $ingressNS \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.annotations."external-dns\.alpha\.kubernetes.io/hostname"=$ingressDNS
wait

echo "ingress installed, annotating the ingress-nginx-controller with the external DNS name $ingressDNS"

nohup kubectl -n kube-ingress annotate svc ingress-nginx-controller external-dns.alpha.kubernetes.io/hostname=
wait

echo "Cluster deployment complete! You can now deploy Veeam Kasten via the microsoft Azure Marketplace or via Helm!"