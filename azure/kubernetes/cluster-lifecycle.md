# AKS Cluster Lifecycle Management

This document covers the complete lifecycle of creating, using, and destroying an AKS cluster for cost-effective learning.

## Cluster Creation

### Prerequisites
1. Azure CLI installed and configured
2. Active Azure subscription
3. kubectl installed
4. Microsoft.ContainerService provider registered

### Register Required Providers
```bash
# Register the Container Service provider
az provider register --namespace Microsoft.ContainerService

# Check registration status
az provider show -n Microsoft.ContainerService --query "registrationState" -o tsv

# Wait for "Registered" status (takes 1-2 minutes)
```

### Create Resource Group
```bash
# Create a resource group for the cluster
az group create \
  --name learning-k8s-rg \
  --location westeurope
```

### Create Cluster

#### Basic Cluster (Free Tier)
```bash
# Create AKS cluster with 2 nodes
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --tier free

# Note: Free tier has no control plane costs
# Only pay for worker nodes and associated resources
```

**Creation Time**: ~3-5 minutes

**Cost**: 2 x Standard_B2s nodes = ~$100/month (including load balancer, disks, etc.)

### Get Credentials
```bash
# Configure kubectl to use the new cluster
az aks get-credentials \
  --resource-group learning-k8s-rg \
  --name learning-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## Cost Optimization Strategies

### Option 1: Minimal Cluster (Cheapest)
```bash
# Single node with smallest VM size
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 1 \
  --node-vm-size Standard_B1s \
  --enable-managed-identity \
  --tier free

# Cost: ~$15-20/month
```

### Option 2: Spot/Low-Priority Nodes
```bash
# Use spot instances (can be evicted)
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --tier free \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1

# Cost: ~60-80% cheaper than regular nodes
```

### Option 3: Autoscaling Cluster
```bash
# Enable cluster autoscaler
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 1 \
  --min-count 1 \
  --max-count 3 \
  --node-vm-size Standard_B2s \
  --enable-cluster-autoscaler \
  --enable-managed-identity \
  --tier free

# Cost: Variable based on workload (scales down when idle)
```

### Option 4: Stop Cluster (Best for Learning)
```bash
# Create cluster normally, then stop when not in use
az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Start when needed
az aks start --resource-group learning-k8s-rg --name learning-cluster

# Benefit: No compute costs while stopped, keeps all configuration
```

## Using the Cluster

### Deploy Sample Application
```bash
# Quick nginx test
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get service nginx --watch

# Wait for EXTERNAL-IP, then test
curl http://EXTERNAL-IP

# Clean up
kubectl delete service nginx
kubectl delete deployment nginx
```

### Monitor Resources
```bash
# Check node utilization
kubectl top nodes

# Check pod utilization
kubectl top pods -A

# View cluster events
kubectl get events --sort-by='.lastTimestamp'

# Check AKS metrics in portal
az aks show \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --query "{powerState:powerState, provisioningState:provisioningState}"
```

## Cluster Shutdown

### Option 1: Stop Cluster (Recommended for Short-Term Savings)

```bash
# Stop the cluster (deallocate nodes)
az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Verify stopped
az aks show \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --query "powerState.code" -o tsv
```

**Stop Time**: ~2-3 minutes

**What happens**:
- Nodes are deallocated (stopped)
- No compute costs while stopped
- Control plane remains available (free tier)
- Configuration persists
- Can restart quickly

**Cost while stopped**: ~$3-5/month (storage, public IP, load balancer)

### Option 2: Delete Cluster (Recommended for Long-Term Savings)

```bash
# Delete the cluster only
az aks delete \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --yes --no-wait

# Delete cluster and resource group
az group delete \
  --name learning-k8s-rg \
  --yes --no-wait
```

**Deletion Time**: ~3-5 minutes

**What gets deleted**:
- All nodes (VMs)
- All node pools
- Managed resource group (MC_*)
- Load balancers
- Public IPs
- Network interfaces
- Virtual machine scale sets

**What persists** (if only deleting cluster):
- Resource group
- Virtual network (if pre-existing)
- Container Registry (if created separately)
- Key Vault (if created separately)

### Verify Deletion

```bash
# Check cluster is deleted
az aks list --resource-group learning-k8s-rg -o table

# Check resource group still exists
az group show --name learning-k8s-rg

# List all resources in resource group
az resource list --resource-group learning-k8s-rg -o table

# Verify managed resource group is deleted
az group list --query "[?starts_with(name, 'MC_learning-k8s-rg')]" -o table
```

### Clean Up Orphaned Resources

```bash
# Sometimes resources persist in the managed resource group
# List managed resource groups
az group list --query "[?starts_with(name, 'MC_')]" -o table

# Delete orphaned managed resource group (if cluster deletion failed)
az group delete --name MC_learning-k8s-rg_learning-cluster_westeurope --yes --no-wait

# Check for orphaned disks
az disk list --query "[?contains(name, 'learning-cluster')]" -o table

# Delete orphaned disk
az disk delete --name DISK_NAME --resource-group RESOURCE_GROUP --yes --no-wait
```

## Cluster Lifecycle Timeline

### Demo Session (What We Did)

| Time | Action | Status |
|------|--------|--------|
| 10:40 | Registered providers | ✓ Complete (~2 min) |
| 10:42 | Created resource group | ✓ Complete |
| 10:43 | Created AKS cluster | ✓ Complete (~4 min) |
| 10:47 | Configured kubectl | ✓ Complete |
| 10:48 | Tested nginx deployment | ✓ Complete |
| 10:50 | Created documentation | ✓ Complete |

**Total Setup Time**: ~10 minutes
**Status**: Cluster is currently **RUNNING**

## Best Practices for Learning

### 1. Use Stop/Start for Daily Use
```bash
# Stop at end of day
az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Start when needed
az aks start --resource-group learning-k8s-rg --name learning-cluster

# Saves ~$3/day compared to keeping it running
```

### 2. Set Budget Alerts
```bash
# Create budget alert via portal
# Navigation: Cost Management + Billing → Budgets
# Recommended: Alert at 50%, 80%, 100% of monthly budget
```

### 3. Use Startup Scripts
```bash
# Save cluster configuration
# Create script: create-cluster.sh
cat > create-cluster.sh <<'EOF'
#!/bin/bash
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --tier free
EOF

chmod +x create-cluster.sh
```

### 4. Bookmark Commands
```bash
# Create aliases for quick access
alias aks-start='az aks start --resource-group learning-k8s-rg --name learning-cluster'
alias aks-stop='az aks stop --resource-group learning-k8s-rg --name learning-cluster'
alias aks-delete='az aks delete --resource-group learning-k8s-rg --name learning-cluster --yes'
```

### 5. Use Azure Cloud Shell
```bash
# Azure Cloud Shell is free with 5GB storage
# Pre-installed with az CLI, kubectl, everything you need
# Access: https://shell.azure.com
```

## Cost Comparison

| Configuration | Monthly Cost | Daily Cost | Best For |
|---------------|--------------|------------|----------|
| 1 x Standard_B1s | ~$15-20 | ~$0.50 | Absolute minimum testing |
| 1 x Standard_B2s (stopped daily) | ~$30-40 | ~$1.00 | Part-time learning |
| 2 x Standard_B2s (running 24/7) | ~$100 | ~$3.30 | Full-time development |
| 2 x Standard_B2s (stopped) | ~$5 | ~$0.15 | Configuration preserved |
| 3 x Standard_D2s_v3 (autoscale) | ~$200+ | ~$6.50+ | Production-like setup |

**For demo/learning**: Use stop/start with Standard_B2s to minimize costs while maintaining flexibility

## Recovery

### Restart Stopped Cluster
```bash
# Start the cluster
az aks start --resource-group learning-k8s-rg --name learning-cluster

# Get credentials (if on new machine)
az aks get-credentials \
  --resource-group learning-k8s-rg \
  --name learning-cluster

# Verify
kubectl get nodes
```

### Recreate Deleted Cluster
```bash
# Use the same commands from creation
az aks create \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --location westeurope \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --tier free

# Get credentials
az aks get-credentials \
  --resource-group learning-k8s-rg \
  --name learning-cluster
```

### Restore Applications
```bash
# If you have manifests saved
kubectl apply -f my-app.yaml

# Or redeploy from scratch
kubectl create deployment nginx --image=nginx:latest
```

## Useful Commands Reference

```bash
# CLUSTER LIFECYCLE
az aks create --resource-group RG --name NAME [OPTIONS]
az aks list --resource-group RG -o table
az aks show --resource-group RG --name NAME
az aks delete --resource-group RG --name NAME --yes

# CLUSTER OPERATIONS
az aks start --resource-group RG --name NAME
az aks stop --resource-group RG --name NAME
az aks scale --resource-group RG --name NAME --node-count N

# CREDENTIALS
az aks get-credentials --resource-group RG --name NAME
az aks get-credentials --resource-group RG --name NAME --overwrite-existing

# COST MONITORING
az aks show --resource-group RG --name NAME --query "agentPoolProfiles[].{vmSize:vmSize,count:count}"
az vm list --resource-group MC_* -o table
az disk list --resource-group MC_* -o table

# NODE POOLS
az aks nodepool list --resource-group RG --cluster-name NAME -o table
az aks nodepool add --resource-group RG --cluster-name NAME --name POOL_NAME
az aks nodepool delete --resource-group RG --cluster-name NAME --name POOL_NAME

# CLEANUP
az aks delete --resource-group RG --name NAME --yes --no-wait
az group delete --name RG --yes --no-wait
```

## Troubleshooting

### Cluster Won't Start
```bash
# Check power state
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "powerState"

# Check for errors in activity log
az monitor activity-log list --resource-group learning-k8s-rg --max-events 10

# Force restart
az aks stop --resource-group learning-k8s-rg --name learning-cluster
sleep 60
az aks start --resource-group learning-k8s-rg --name learning-cluster
```

### Cluster Won't Delete
```bash
# Check deletion status
az aks show --resource-group learning-k8s-rg --name learning-cluster

# If cluster is stuck, force delete resource group
az group delete --name learning-k8s-rg --yes --force

# Delete managed resource group manually if needed
az group delete --name MC_learning-k8s-rg_learning-cluster_westeurope --yes --force
```

### Orphaned Load Balancers
```bash
# These can continue charging
# List all load balancers in managed resource group
az network lb list --resource-group MC_learning-k8s-rg_learning-cluster_westeurope -o table

# Delete manually
az network lb delete --name LB_NAME --resource-group RESOURCE_GROUP
```

### Billing Concerns
```bash
# View cost analysis
# Portal: Cost Management + Billing → Cost analysis

# Check current month costs by resource
az consumption usage list --query "[?contains(instanceName, 'learning-cluster')]" -o table

# Set spending limits
# Portal: Cost Management + Billing → Budgets
```

## Summary

**Key Takeaway**: For learning and demo purposes:
1. Use Free tier AKS (no control plane costs)
2. Use **stop/start** for daily work (best balance of cost and convenience)
3. Use smallest viable VM size (Standard_B1s or Standard_B2s)
4. **Delete cluster** if not using for weeks (saves storage costs)
5. Set billing alerts
6. Verify deletion/stop completed

**Cost Comparison**:
- Running 24/7: ~$100/month
- Stop when not in use (8 hours/day): ~$30-40/month
- Stopped completely: ~$5/month
- Deleted: $0/month

**Savings**: Up to 97% by managing cluster power state effectively
