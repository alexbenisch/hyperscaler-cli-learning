# GKE (Google Kubernetes Engine) Setup

This directory contains information about the GKE cluster setup for learning purposes.

## Current Cluster

**Cluster Name**: `learning-cluster`
**Project**: `gcp-477815`
**Region**: `europe-west3` (Frankfurt)
**Master Version**: `1.33.5-gke.1201000`
**Master IP**: `35.242.227.145`
**Node Count**: 6 nodes (2 per zone across 3 zones)
**Machine Type**: `e2-medium` (2 vCPU, 4GB RAM)
**Disk**: 30GB standard persistent disk per node

### Zones
- europe-west3-a
- europe-west3-b
- europe-west3-c

### Features Enabled
- Autoupgrade
- Autorepair
- IP Alias (VPC-native cluster)

### Features Disabled (Cost Optimization)
- Cloud Logging
- Cloud Monitoring

## Cluster Access

### Get Credentials
```bash
gcloud container clusters get-credentials learning-cluster --region=europe-west3
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
gcloud container clusters describe learning-cluster --region=europe-west3
```

## Cluster Management

### View Cluster in Console
```bash
# Open in browser
gcloud container clusters list --uri
```

Console URL: https://console.cloud.google.com/kubernetes/workload_/gcloud/europe-west3/learning-cluster?project=gcp-477815

### Resize Cluster
```bash
# Scale to different number of nodes per zone
gcloud container clusters resize learning-cluster \
  --region=europe-west3 \
  --num-nodes=3
```

### Upgrade Cluster
```bash
# List available versions
gcloud container get-server-config --region=europe-west3

# Upgrade master
gcloud container clusters upgrade learning-cluster \
  --region=europe-west3 \
  --master \
  --cluster-version=VERSION

# Upgrade nodes
gcloud container clusters upgrade learning-cluster \
  --region=europe-west3
```

### Delete Cluster
```bash
# Delete the cluster (this will delete all resources)
gcloud container clusters delete learning-cluster --region=europe-west3
```

## Cost Information

Estimated monthly cost for this cluster:
- **6 x e2-medium nodes**: ~$150/month
- **Network egress**: Variable
- **Persistent disks**: ~$12/month (6 x 30GB standard)

**Total**: ~$162/month

Cost optimization tips:
- Use preemptible nodes for non-production workloads (--preemptible flag)
- Enable autoscaling to scale down during low usage
- Use smaller machine types for testing
- Delete the cluster when not in use

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
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
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
    targetPort: 8080
EOF

# Check deployment
kubectl get deployments
kubectl get pods
kubectl get service hello-service

# Clean up
kubectl delete service hello-service
kubectl delete deployment hello-app
```

## Troubleshooting

### Authentication Issues
If you see authentication errors:
```bash
# Ensure gke-gcloud-auth-plugin is installed
which gke-gcloud-auth-plugin

# On Arch Linux
yay -S aur/google-cloud-cli-gke-gcloud-auth-plugin

# Re-fetch credentials
gcloud container clusters get-credentials learning-cluster --region=europe-west3
```

### Connection Issues
```bash
# Check cluster status
gcloud container clusters list

# Verify kubectl context
kubectl config current-context

# Test connection
kubectl cluster-info
```

### Node Issues
```bash
# Check node status
kubectl get nodes

# Describe node
kubectl describe node NODE_NAME

# Check node logs (from GCP Console)
gcloud compute ssh NODE_NAME --zone=ZONE
```

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [GKE Pricing Calculator](https://cloud.google.com/products/calculator)
- [Cluster Lifecycle Management](cluster-lifecycle.md) - Detailed guide on creating and deleting clusters

## Cluster History

### Demo Session - 2025-11-10
**Created**: 2025-11-10 ~15:48 UTC
**Deleted**: 2025-11-10 ~16:00 UTC
**Runtime**: ~10 minutes
**Cost**: ~$0.35

**Configuration**:
- Region: europe-west3 (Frankfurt, Germany)
- Nodes: 6 x e2-medium (2 per zone)
- Purpose: Learning and experimentation with GKE
- Status: **DELETED** (cluster no longer exists)

**Key Learnings**:
- Regional clusters create nodes across 3 zones automatically
- GKE auth plugin required for kubectl access on Arch Linux
- Cluster creation takes ~5 minutes, deletion takes ~3 minutes
- Always delete clusters after demo/testing to avoid ongoing costs

To recreate this cluster, see the commands in [cluster-lifecycle.md](cluster-lifecycle.md)
