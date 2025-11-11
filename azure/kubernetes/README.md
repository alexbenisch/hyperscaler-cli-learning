# AKS (Azure Kubernetes Service) Setup

This directory contains information about the AKS cluster setup for learning purposes.

## Current Cluster

**Cluster Name**: `learning-cluster`
**Resource Group**: `learning-k8s-rg`
**Location**: `westeurope` (Netherlands)
**Kubernetes Version**: `1.32.7`
**Master FQDN**: `learning-c-learning-k8s-rg-c3a4d3-azkenk5m.hcp.westeurope.azmk8s.io`
**Node Count**: 2 nodes
**VM Size**: `Standard_B2s` (2 vCPU, 4GB RAM)
**OS Disk**: 128GB managed disk per node
**Tier**: Free

### Node Pool
- Name: nodepool1
- Mode: System
- Max Pods per Node: 250
- OS: Ubuntu 22.04.5 LTS
- Container Runtime: containerd 1.7.28

### Features Enabled
- Auto node OS upgrade
- Managed identity
- RBAC
- Disk CSI driver
- File CSI driver
- Snapshot controller

### Networking
- Network Plugin: Azure CNI (Overlay mode)
- Network Policy: None
- Pod CIDR: 10.244.0.0/16
- Service CIDR: 10.0.0.0/16
- DNS Service IP: 10.0.0.10
- Load Balancer: Standard SKU

## Cluster Access

### Get Credentials
```bash
az aks get-credentials --resource-group learning-k8s-rg --name learning-cluster
```

### Basic Commands
```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes -o wide

# List all pods
kubectl get pods -A

# Get cluster details
az aks show --resource-group learning-k8s-rg --name learning-cluster
```

## Cluster Management

### View Cluster in Portal
```bash
# Open in browser
az aks browse --resource-group learning-k8s-rg --name learning-cluster
```

Portal URL: https://portal.azure.com/#resource/subscriptions/c3a4d3b0-45ee-4c1b-a3ab-24974b193a58/resourceGroups/learning-k8s-rg/providers/Microsoft.ContainerService/managedClusters/learning-cluster

### Scale Cluster
```bash
# Scale to different number of nodes
az aks scale \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --node-count 3
```

### Upgrade Cluster
```bash
# List available versions
az aks get-upgrades --resource-group learning-k8s-rg --name learning-cluster -o table

# Upgrade cluster
az aks upgrade \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --kubernetes-version VERSION
```

### Delete Cluster
```bash
# Delete the cluster (this will delete all resources in the managed resource group)
az aks delete --resource-group learning-k8s-rg --name learning-cluster --yes --no-wait

# Delete the entire resource group (including the cluster)
az group delete --name learning-k8s-rg --yes --no-wait
```

## Cost Information

Estimated monthly cost for this cluster:
- **2 x Standard_B2s nodes**: ~$60/month
- **Load Balancer**: ~$18/month
- **Public IP**: ~$3/month
- **Disk storage**: ~$20/month (2 x 128GB managed)

**Total**: ~$100/month

Cost optimization tips:
- Use spot instances for non-production workloads
- Enable cluster autoscaler to scale down during low usage
- Use smaller VM sizes for testing (Standard_B1s, Standard_B1ms)
- Stop the cluster when not in use (az aks stop)
- Delete the cluster when not needed for extended periods

## Deploy Sample Application

### Deploy nginx
```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Expose with LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check service (wait for EXTERNAL-IP)
kubectl get service nginx --watch

# Test
curl http://EXTERNAL-IP

# Clean up
kubectl delete service nginx
kubectl delete deployment nginx
```

### Deploy with manifest
```bash
# Create a sample deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  type: LoadBalancer
  selector:
    app: hello
  ports:
  - port: 80
    targetPort: 80
EOF

# Check deployment
kubectl get deployments
kubectl get pods
kubectl get service hello-service

# Clean up
kubectl delete service hello-service
kubectl delete deployment hello-app
```

## Cluster Operations

### Start/Stop Cluster (Cost Savings)
```bash
# Stop cluster (saves compute costs, keeps configuration)
az aks stop --resource-group learning-k8s-rg --name learning-cluster

# Start cluster
az aks start --resource-group learning-k8s-rg --name learning-cluster

# Check power state
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "powerState"
```

### Add Node Pool
```bash
# Add a new node pool
az aks nodepool add \
  --resource-group learning-k8s-rg \
  --cluster-name learning-cluster \
  --name nodepool2 \
  --node-count 1 \
  --node-vm-size Standard_B2s

# List node pools
az aks nodepool list \
  --resource-group learning-k8s-rg \
  --cluster-name learning-cluster -o table
```

## Troubleshooting

### Authentication Issues
If you see authentication errors:
```bash
# Re-fetch credentials
az aks get-credentials \
  --resource-group learning-k8s-rg \
  --name learning-cluster \
  --overwrite-existing

# Verify connection
kubectl cluster-info
```

### Connection Issues
```bash
# Check cluster status
az aks show --resource-group learning-k8s-rg --name learning-cluster --query "powerState"

# Verify kubectl context
kubectl config current-context

# Test connection
kubectl get nodes
```

### Node Issues
```bash
# Check node status
kubectl get nodes

# Describe node
kubectl describe node NODE_NAME

# View node pool status
az aks nodepool show \
  --resource-group learning-k8s-rg \
  --cluster-name learning-cluster \
  --name nodepool1
```

### View Activity Logs
```bash
# View recent cluster operations
az monitor activity-log list \
  --resource-group learning-k8s-rg \
  --max-events 10 \
  --query "[].{Time:eventTimestamp, Operation:operationName.localizedValue, Status:status.localizedValue}" \
  -o table
```

## Additional Resources

- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Cluster Lifecycle Management](cluster-lifecycle.md) - Detailed guide on creating and deleting clusters

## Cluster History

### Demo Session - 2025-11-11
**Created**: 2025-11-11 ~10:45 UTC
**Deleted**: 2025-11-11 ~10:58 UTC
**Runtime**: ~13 minutes
**Cost**: ~$0.45

**Configuration**:
- Location: westeurope (Netherlands)
- Nodes: 2 x Standard_B2s
- Purpose: Learning and experimentation with AKS
- Kubernetes Version: 1.32.7
- Status: **DELETED** (cluster no longer exists)

**Key Learnings**:
- AKS requires Microsoft.ContainerService provider to be registered
- Free tier available (no control plane costs)
- Cluster creation takes ~3-5 minutes
- Load balancer provisioning takes ~30 seconds
- Can stop/start clusters to save costs without full deletion
- Always delete clusters after demo/testing to avoid ongoing costs

To recreate this cluster, see the commands in [cluster-lifecycle.md](cluster-lifecycle.md)
