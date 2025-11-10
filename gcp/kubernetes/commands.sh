#!/bin/bash
# GKE Quick Reference Commands
# Cluster: learning-cluster
# Region: europe-west3

# === CLUSTER MANAGEMENT ===

# Get cluster credentials
gcloud container clusters get-credentials learning-cluster --region=europe-west3

# List clusters
gcloud container clusters list

# Describe cluster
gcloud container clusters describe learning-cluster --region=europe-west3

# Resize cluster (change number of nodes per zone)
# gcloud container clusters resize learning-cluster --region=europe-west3 --num-nodes=3

# Delete cluster (CAREFUL!)
# gcloud container clusters delete learning-cluster --region=europe-west3

# === KUBECTL BASICS ===

# Cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes
kubectl get nodes -o wide

# Get all resources
kubectl get all --all-namespaces

# Get pods in all namespaces
kubectl get pods -A

# Get services
kubectl get services -A

# === DEPLOY SAMPLE APP ===

# Quick nginx deployment
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get service nginx --watch

# Delete nginx
# kubectl delete service nginx
# kubectl delete deployment nginx

# === MONITORING ===

# Get cluster events
kubectl get events --sort-by='.lastTimestamp'

# Watch pods
kubectl get pods -A --watch

# Check resource usage
kubectl top nodes
kubectl top pods -A

# === DEBUGGING ===

# Describe node
kubectl describe node NODE_NAME

# Get pod logs
kubectl logs POD_NAME -n NAMESPACE

# Execute command in pod
kubectl exec -it POD_NAME -- /bin/bash

# Port forward
kubectl port-forward POD_NAME 8080:80

# === CONTEXTS ===

# Get current context
kubectl config current-context

# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context CONTEXT_NAME

# === COST MONITORING ===

# Check cluster cost (requires billing API)
# gcloud beta billing projects describe gcp-477815

# List compute instances (underlying VMs)
gcloud compute instances list --filter="name~learning-cluster"

# === CLEANUP ===

# Delete all resources in a namespace
# kubectl delete all --all -n NAMESPACE

# Delete cluster (saves costs when not in use)
# gcloud container clusters delete learning-cluster --region=europe-west3 --quiet
