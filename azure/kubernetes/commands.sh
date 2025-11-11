#!/bin/bash
# AKS Quick Reference Commands
# Cluster: learning-cluster
# Resource Group: learning-k8s-rg
# Location: westeurope

# === CLUSTER MANAGEMENT ===

# Get cluster credentials
az aks get-credentials --resource-group learning-k8s-rg --name learning-cluster

# List clusters
az aks list --resource-group learning-k8s-rg -o table

# Show cluster details
az aks show --resource-group learning-k8s-rg --name learning-cluster

# Start cluster
az aks start --resource-group learning-k8s-rg --name learning-cluster

# Stop cluster (saves costs)
az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Check power state
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "powerState.code" -o tsv

# Scale cluster (change number of nodes)
# az aks scale --resource-group learning-k8s-rg --name learning-cluster --node-count 3

# Delete cluster (CAREFUL!)
# az aks delete --resource-group learning-k8s-rg --name learning-cluster --yes

# Delete entire resource group (CAREFUL!)
# az group delete --name learning-k8s-rg --yes

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

# === NODE POOLS ===

# List node pools
az aks nodepool list --resource-group learning-k8s-rg --cluster-name learning-cluster -o table

# Show node pool details
az aks nodepool show --resource-group learning-k8s-rg --cluster-name learning-cluster --name nodepool1

# Add node pool
# az aks nodepool add --resource-group learning-k8s-rg --cluster-name learning-cluster --name nodepool2 --node-count 1

# Delete node pool
# az aks nodepool delete --resource-group learning-k8s-rg --cluster-name learning-cluster --name nodepool2

# === MONITORING ===

# Get cluster events
kubectl get events --sort-by='.lastTimestamp'

# Watch pods
kubectl get pods -A --watch

# Check resource usage
kubectl top nodes
kubectl top pods -A

# View activity logs
az monitor activity-log list --resource-group learning-k8s-rg --max-events 10 -o table

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

# === UPGRADES ===

# Check available upgrades
az aks get-upgrades --resource-group learning-k8s-rg --name learning-cluster -o table

# Upgrade cluster
# az aks upgrade --resource-group learning-k8s-rg --name learning-cluster --kubernetes-version VERSION

# === COST MONITORING ===

# Show cluster configuration (including VM sizes and counts)
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "{vmSize:agentPoolProfiles[0].vmSize, nodeCount:agentPoolProfiles[0].count}"

# List VMs in managed resource group
az vm list --resource-group MC_learning-k8s-rg_learning-cluster_westeurope -o table

# List disks in managed resource group
az disk list --resource-group MC_learning-k8s-rg_learning-cluster_westeurope -o table

# List load balancers
az network lb list --resource-group MC_learning-k8s-rg_learning-cluster_westeurope -o table

# === RESOURCE GROUP OPERATIONS ===

# List resource groups
az group list -o table

# Show resource group
az group show --name learning-k8s-rg

# List all resources in resource group
az resource list --resource-group learning-k8s-rg -o table

# === CLEANUP ===

# Delete all resources in a namespace
# kubectl delete all --all -n NAMESPACE

# Stop cluster (saves most costs, keeps configuration)
# az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Delete cluster (saves all costs except storage)
# az aks delete --resource-group learning-k8s-rg --name learning-cluster --yes --no-wait

# Delete resource group and everything in it
# az group delete --name learning-k8s-rg --yes --no-wait

# === TROUBLESHOOTING ===

# Check cluster provisioning state
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "provisioningState" -o tsv

# Check node provisioning state
az aks nodepool show --resource-group learning-k8s-rg --cluster-name learning-cluster --name nodepool1 --query "provisioningState" -o tsv

# Re-fetch credentials (if having auth issues)
az aks get-credentials --resource-group learning-k8s-rg --name learning-cluster --overwrite-existing

# Check Azure provider registration
az provider show -n Microsoft.ContainerService --query "registrationState" -o tsv

# === HELPFUL ALIASES ===

# Add to ~/.bashrc or ~/.zshrc:
# alias aks-start='az aks start --resource-group learning-k8s-rg --name learning-cluster'
# alias aks-stop='az aks stop --resource-group learning-k8s-rg --name learning-cluster'
# alias aks-creds='az aks get-credentials --resource-group learning-k8s-rg --name learning-cluster'
# alias aks-status='az aks show --resource-group learning-k8s-rg --name learning-cluster --query "{powerState:powerState.code, provisioningState:provisioningState}" -o table'
