---
author: michaelcade
date: 2024-04-25 16:21:37 +0100
description: ""
featured: false
image: ""
image_caption: ""
layout: post
published: true
tags: [kasten, gitops, cicd, argocd, pipelines]
title: "Integrating Backups into your GitOps Pipeline "
---

# Integrating Backups into your GitOps Pipeline 

This post is going to uncover some of the realities that we face around companies adopting a GitOps model within their infrastructure and operational procedures. Ultimately GitOps is going to rely on Git as a source control system. 

The industry definition can be found below: 

*GitOps is an operational framework based on DevOps practices, like continuous integration/continuous delivery (CI/CD) and version control, which automates infrastructure and manages software deployment.*

[Atlassian - Is GitOps the next big thing in DevOps?](https://www.atlassian.com/git/tutorials/gitops)

## My thoughts on GitOps 

I may also refer to GitOps in this post according to CI/CD as well because this can be seen as maybe the predecessor to GitOps. My take is that maybe you are not a software development house today so maybe CI "Continious Integration" is not something that crosses your mind, however CD (Continous Delivery) will absolutely be something every single customer running some sort of software should be considering deploying their software the GitOps way. 

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture1.png)

In looking at the diagram above if you are consuming off the shelf software within your environments, as software companies are speeding up delivery of software where v1 to v2 is now weeks vs a year or even longer, then GitOps is going to help you stay in control of these updates and provide you a good way to keep track but also provide a rollback workflow when bad things happen. Now if you only have one off the shelf software in your environment maybe this is a stretch but if you have lots of COTS (Commercial off the shelf software) then a GitOps way is going to help with that control. 

## Introducing ArgoCD 

In our example we are going to focus on ArgoCD and specifically Kubernetes as our platform to run our applications. 

*Argo CD is a Kubernetes-native continuous deployment (CD) tool. Unlike external CD tools that only enable push-based deployments, Argo CD can pull updated code from Git repositories and deploy it directly to Kubernetes resources.*

As you can see from the above description, ArgoCD is specifically built for Kubernetes and will pull updates from git based repositories but it also works with helm charts as well, which today is still the defacto package manager for Kubernetes. 

For the example we are going to walk through we are going to be using a git based repository with ArgoCD to get our Kubernetes based application up and running. You can see what this application looks like below. 

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture2.png)

## GitOps plus Data 

For those that studied the application architecture above you will have seen there is a persistent volume... in particular this is using a MySQL database to store our mission critical data. 

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture3.png)

Whilst our git repository is great for the Kubernetes objects, the source code has no idea about the database and the contents of the database. 

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture4.png)

When it comes to that database and important data, this is not going to be captured in version control systems. 

Any persistent data or volumes used by applications are not captured in version control

Example: any stateful service, such as a relational database or NoSQL system

Requires the entire application stack including the data!

Data, and the dependencies of the stack on the data be discovered, tracked, and captured.

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture5.png)

It is because of this that we have to somehow also protect that data at specific times throughout the lifecycle of the apps, the best time for this happening is going to be between versions as well as maybe a more scheduled approach to combat other failure sceanrios. 

In our walkthrough demo below we are going to do just that, we are going to take an application which has a database element to this also running alongside the application inside the Kubernetes cluster, I will add though that this same process can be done with external data services. 

I have also ran through this just for the data service using Kanister.

## Walkthrough demo 

Now we are going to play a little game, if you would like to follow along with this part of the post then you will find the steps [here](https://github.com/michaelcade/argocd-kasten)

In the example above we use minikube (In the most recent releases the addons used here are not working with volumesnapshots or csi-hostpath-driver) in order to get these addons we have to do that manually or you will have to find a functional cluster with the CSI standard being used along with volumesnapshot capabilities. 

The steps we will cover here will be: 

- A Kubernetes cluster with CSI capabilities available 
- Deploy Kasten 
- Deploy ArgoCD 
- Set up Application via ArgoCD 
- Add some data 
- Create ConfigMap to help manipulate data
- Failure Scenario 
- The Recovery 
- Righting our wrongs 

Ok lets get cooking.. 

I am going to assume at this point that you have a working Kubernetes cluster and you have been through with the Kasten primer and confirmed that your CSI is configured correctly. 

On that cluster we are then going to deploy Kasten, again a simple helm chart deployment in your Kubernetes cluster of choice 

[Kasten install steps](https://docs.kasten.io/latest/install/index.html)

## Deploy ArgoCD

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

Username is admin and password can be obtained with this command.

``` 
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Set up Application via ArgoCD 

First let us confirm that we do not have a namespace called mysql as this will be created within ArgoCD

We create a mysql app for sterilisation of animals in a pet clinic. 

This app is deployed with Argo CD and is made of : 
*  A mysql deployment 
*  A PVC 
*  A secret 
*  A service to mysql 

This is the URL required for ArgoCD - https://github.com/MichaelCade/argocd-kasten.git

We also use a pre-sync job (with corresponding sa and rolebinding)to backup the whole application with kasten before application sync. 

At the first sync an empty restore point should be created.

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture6.png)

## Add some data

Vets are creating the row of the animal they will operate. 

```
mysql_pod=$(kubectl get po -n mysql -l app=mysql -o jsonpath='{.items[*].metadata.name}')
kubectl exec -ti $mysql_pod -n mysql -- bash

mysql --user=root --password=ultrasecurepassword
CREATE DATABASE test;
USE test;
CREATE TABLE pets (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);
INSERT INTO pets VALUES ('Puffball','Diane','hamster','f','2021-05-30',NULL);
INSERT INTO pets VALUES ('Sophie','Meg','giraffe','f','2021-05-30',NULL);
INSERT INTO pets VALUES ('Sam','Diane','snake','m','2021-05-30',NULL);
INSERT INTO pets VALUES ('Medor','Meg','dog','m','2021-05-30',NULL);
INSERT INTO pets VALUES ('Felix','Diane','cat','m','2021-05-30',NULL);
INSERT INTO pets VALUES ('Joe','Diane','crocodile','f','1984-05-30',NULL);
INSERT INTO pets VALUES ('Vanny','Veeam Vanguards','vulture','m','2019-05-30',NULL);
SELECT * FROM pets;
exit
exit
```

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture7.png)

## Create ConfigMap to help manipulate data

We create a config map that contains the list of species that won't be eligible for sterilisation. This was decided based on the experience of this clinic, operation on this species are too expansive. We can see here a link between the configuration and the data. It's very important that configuration and data are captured together.

```
cat <<EOF > forbidden-species-cm.yaml 
apiVersion: v1
data:
  species: "('crocodile','hamster')"
kind: ConfigMap
metadata:
  name: forbidden-species
EOF 
git add forbidden-species-cm.yaml
git commit -m "Adding forbidden species" 
git push
```

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture8.png)

When deploying the app with Argo Cd we can see that a second restore point has been created

## Failure Scenario

At this stage of our application we want to remove all the rows that have species in the list, for that we use a job that connects to the database and that deletes the rows. 

But we made a mistake in the code and we accidentally delete other rows. 

Notice that we use the wave 2 `argocd.argoproj.io/sync-wave: "2"` to make sure this job is executed after the kasten job.

```
cat <<EOF > migration-data-job.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: migration-data-job
  annotations: 
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/sync-wave: "2"
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command: 
        - /bin/bash
        - -c
        - |
          #!/bin/bash
          # Oh no !! I forgot to the "where species in ${SPECIES}" clause in the delete command :(
          mysql -h mysql -p\${MYSQL_ROOT_PASSWORD} -uroot -Bse "delete from test.pets"
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-root-password
              name: mysql        
        - name: SPECIES
          valueFrom:
            configMapKeyRef:
              name: forbidden-species
              key: species      
        image: docker.io/bitnami/mysql:8.0.23-debian-10-r0
        name: data-job
      restartPolicy: Never
EOF 
git add migration-data-job.yaml
git commit -m "migrate the data to remove the forbidden species from the database, oh no I made a mistake, that will remove all the species !!" 
git push
```
now head on back to ArgoCD and sync again and see what damage it has done to our database. 

Lets now take a look at the database state after making the mistake 

```
mysql_pod=$(kubectl get po -n mysql -l app=mysql -o jsonpath='{.items[*].metadata.name}')
kubectl exec -ti $mysql_pod -n mysql -- bash
mysql --user=root --password=ultrasecurepassword
USE test;
SELECT * FROM pets;
```
![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture9.png)

## The Recovery
At this stage we could roll back our ArgoCD to our previous version, prior to Phase 4 but you will notice that this just brings back our configuration and it is not going to bring back our data! 

Fortunately we can use kasten to restore the data using the restore point.

You will see from the above now when we check the database our data is gone! It was lucky that we have this presync enabled to take those backups prior to any code changes. We can now use that restore point to bring back our data. 

Lets now take a look at the database state after recovery 

```
mysql_pod=$(kubectl get po -n mysql -l app=mysql -o jsonpath='{.items[*].metadata.name}')
kubectl exec -ti $mysql_pod -n mysql -- bash
mysql --user=root --password=ultrasecurepassword
USE test;
SELECT * FROM pets;
```

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture10.png)

## Righting our wrongs
We have rectified our mistake in the code and would like to correctly implement this now into our application. 

```
cat <<EOF > migration-data-job.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: migration-data-job
  annotations: 
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/sync-wave: "2"
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command: 
        - /bin/bash
        - -c
        - |
          #!/bin/bash
          # Oh no !! I forgot to the "where species in ${SPECIES}" clause in the delete command :(
          mysql -h mysql -p\${MYSQL_ROOT_PASSWORD} -uroot -Bse "delete from test.pets where species in \${SPECIES}" 
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-root-password
              name: mysql        
        - name: SPECIES
          valueFrom:
            configMapKeyRef:
              name: forbidden-species
              key: species      
        image: docker.io/bitnami/mysql:8.0.23-debian-10-r0
        name: data-job
      restartPolicy: Never
EOF 
git add migration-data-job.yaml
git commit -m "migrate the data to remove the forbidden species from the database, oh no I made a mistake, that will remove all the species !!" 
git push
```

Lets now take a look at the database state and make sure we now have the desired outcome.

```
mysql_pod=$(kubectl get po -n mysql -l app=mysql -o jsonpath='{.items[*].metadata.name}')
kubectl exec -ti $mysql_pod -n mysql -- bash
mysql --user=root --password=ultrasecurepassword
USE test;
SELECT * FROM pets;
```

At this stage you will have your desired data in your database but peace of mind that you have a way of recovering if this accident happens again. 

![](/images/posts/2024-04-25-integrating-backups-into-gitops/Picture11.png)

This post was to highlight the importance of data within our applications, remember I also mentioned that this MySQL or any other data service might also be external to the Kubernetes cluster but the same issues can apply, if you manipulate that data in this way or in any other way your version control system does not capture or have any awareness of what is in the database. 


