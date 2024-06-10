---
layout: post
title: Protecting RabbitMQ with Kasten
description: We saw recently how to protect Kafka but can we protect the other major messaging application with Kasten too?
date: 2024-06-05 14:00:00 +0000
author: jamestate
image: '/images/posts/2024-06-05-protecting-rabbitmq/rabbitmq.png'
image_caption: 'How to protect RabbitMQ with kasten'
tags: [rabbitmq, kasten, messaging]
featured: false
---

I recently wrote an [article](./kasten-and-strimzi-kafka) covering off how we handle the backup & restore of Kafka via the Strimzi operator. A colleague of mine mentioned the other popular messaging application, RabbitMQ, and wondered if it would work in the same fashion, so I decided to spin up an MQ cluster and investigate.

## Deploying the RabbitMQ operator

The RabbitMQ operator works in much the same fashion as the Strimzi one does for Kafka, it is deployed in it's own namespace and acts as a watcher for rabbit cluster configs deployed in other namespaces on the cluster. Once it detects this rabbit cluster config it will deploy the resources in that end namespace based upon the settings in the rabbit config.

The deployment of the operator is a single one line command:

```
$ kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

namespace/rabbitmq-system created
customresourcedefinition.apiextensions.k8s.io/rabbitmqclusters.rabbitmq.com created
serviceaccount/rabbitmq-cluster-operator created
role.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-role created
clusterrole.rbac.authorization.k8s.io/rabbitmq-cluster-operator-role created
rolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-operator-rolebinding created
deployment.apps/rabbitmq-cluster-operator created
```

You can then create a separate namespace for the messaging application and deploy the cluster config:

```
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  labels:
    app: rabbitmq
  name: rabbitmq
spec:
  replicas: 3
  image: rabbitmq:latest
  service:
    type: ClusterIP
  persistence:
    storageClassName: longhorn
    storage: 10Gi
  resources:
    requests:
      cpu: 256m
      memory: 1Gi
    limits:
      cpu: 256m
      memory: 1Gi
  rabbitmq:
    additionalPlugins:
      - rabbitmq_management
      - rabbitmq_peer_discovery_k8s
    additionalConfig: |
      cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      cluster_formation.k8s.address_type = hostname
      vm_memory_high_watermark_paging_ratio = 0.85
      cluster_formation.node_cleanup.interval = 10
      cluster_partition_handling = autoheal
      queue_master_locator = min-masters
      loopback_users.guest = false
      default_user = guest
      default_pass = guest
    advancedConfig: ""
```

We can see the PVC's binding and pods active:

```
root@rke2:/home/jtate/rabbitmq# k get pvc -A
NAMESPACE   NAME                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
heimdall    heimdall-config                 Bound    pvc-c1829f24-eed9-4f33-98b7-74d3715ab3c8   17Gi       RWO            longhorn       58d
kasten-io   catalog-pv-claim                Bound    pvc-973b0867-cd0d-4fcc-9140-cf2097088fdc   20Gi       RWO            longhorn       136d
kasten-io   jobs-pv-claim                   Bound    pvc-f71770f2-2389-41b3-9b11-9806e2a0261d   20Gi       RWO            longhorn       136d
kasten-io   k10-grafana                     Bound    pvc-4aa7ceb2-a78a-4b78-989d-7a19777e2243   5Gi        RWO            longhorn       136d
kasten-io   kubestr-csi-original-pvchd5mf   Bound    pvc-1f87ee5a-57d1-414f-be76-5811a1803f7a   1Gi        RWO            longhorn       129d
kasten-io   logging-pv-claim                Bound    pvc-4065d423-8d7b-4223-9b31-713ed561079f   20Gi       RWO            longhorn       136d
kasten-io   metering-pv-claim               Bound    pvc-eb3824ce-0f42-4b1d-bb4f-37d3dac6d3a9   2Gi        RWO            longhorn       136d
kasten-io   prometheus-server               Bound    pvc-a03b291b-9fdd-41e8-b85c-58b287b1d579   8Gi        RWO            longhorn       136d
nginx-nfs   nfs-pvc                         Bound    pvc-83a6f971-8a40-40ed-9bbb-70cba0e32e10   5Gi        RWO            nfs-client     72d
pacman      pacman-mongodb                  Bound    pvc-444ca396-009e-4e57-bae5-89842dc01ee3   8Gi        RWO            longhorn       28h
puter       puter-claim0                    Bound    pvc-56ebab34-d252-4530-ba6f-fd6bb28aa88f   10Gi       RWO            longhorn       25h
puter       puter-claim1                    Bound    pvc-4fbd68e7-3307-4323-91ae-1ee4f0d2f2c4   10Gi       RWO            longhorn       25h
rabbitapp   persistence-rabbitmq-server-0   Bound    pvc-bbf65892-0c67-46a7-ae5b-d0079ca4bea6   10Gi       RWO            longhorn       23s
rabbitapp   persistence-rabbitmq-server-1   Bound    pvc-4392eb71-7a64-4623-8806-051bb1a0fefa   10Gi       RWO            longhorn       23s
rabbitapp   persistence-rabbitmq-server-2   Bound    pvc-481af4cb-9202-4bc0-a3aa-8f0843fa082a   10Gi       RWO            longhorn       23s


root@rke2:/home/jtate/rabbitmq# k get po -n rabbitapp
NAME                READY   STATUS    RESTARTS   AGE
rabbitmq-server-0   1/1     Running   0          5m18s
rabbitmq-server-1   1/1     Running   0          5m18s
rabbitmq-server-2   1/1     Running   0          5m18s
```

You are now free to backup the application namespace in the standard fashion, ie via the normal snapshot methodology. Once deployed, an ingress rule can be created to gain access to the RabbitMQ dashboard:

```
Service: rabbitmq
Port: 15872
```

![Dashboard](/images/posts/2024-06-05-protecting-rabbitmq/1.png)

## Restoring the application

Now that we have a backup on a secure external location, we can proceed to delete the app namespace and do a restore action to bring it back. When selecting the resources for restore, only allow the following (PVC's, configmaps, secrets and rabbitmqclusters):

![Restore Selection](images/posts/2024-06-05-protecting-rabbitmq/2.png)

Once the restore completes, check that the pvc's are present, the pods come up and the application is presented via ingress:

```
root@rke2:/home/jtate# k get po -n rabbitapp
NAME                READY   STATUS    RESTARTS   AGE
rabbitmq-server-0   1/1     Running   0          2m8s
rabbitmq-server-1   1/1     Running   0          4m3s
rabbitmq-server-2   1/1     Running   0          5m54s
root@rke2:/home/jtate# k get pvc -n rabbitapp
NAME                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistence-rabbitmq-server-0   Bound    pvc-8226af6e-baa0-4ce9-a541-0538f2b57d76   10Gi       RWO            longhorn       8m11s
persistence-rabbitmq-server-1   Bound    pvc-4985122b-498e-4116-85cd-3c570fc080e0   10Gi       RWO            longhorn       8m21s
persistence-rabbitmq-server-2   Bound    pvc-6368a7d7-5d27-44f1-95f2-093c9f94dc7d   10Gi       RWO            longhorn       8m11s
```

## Conclusion

Much like Kafka, RabbitMQ can be easy to protect when used in conjunction with an intelligent operator.
