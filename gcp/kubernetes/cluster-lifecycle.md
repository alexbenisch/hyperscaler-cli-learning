# GKE Cluster Lifecycle Management

This document covers the complete lifecycle of creating, using, and destroying a GKE cluster for cost-effective learning.

## Cluster Creation

### Prerequisites
1. Google Cloud CLI installed and configured
2. GKE auth plugin installed (`google-cloud-cli-gke-gcloud-auth-plugin`)
3. Active GCP project with billing enabled
4. Compute Engine and Container APIs enabled

### Enable Required APIs
```bash
# Enable the necessary APIs
gcloud services enable compute.googleapis.com container.googleapis.com
```

### Create Cluster
```bash
# Basic cluster creation (regional for high availability)
gcloud container clusters create learning-cluster \
  --region=europe-west3 \
  --num-nodes=2 \
  --machine-type=e2-medium \
  --disk-size=30 \
  --disk-type=pd-standard \
  --enable-autoupgrade \
  --enable-autorepair \
  --enable-ip-alias \
  --no-enable-cloud-logging \
  --no-enable-cloud-monitoring

# Note: Regional clusters create nodes across 3 zones
# --num-nodes=2 means 2 nodes per zone = 6 total nodes
```

**Creation Time**: ~5-10 minutes

**Cost**: Regional cluster with 6 x e2-medium nodes = ~$162/month

### Get Credentials
```bash
# Configure kubectl to use the new cluster
gcloud container clusters get-credentials learning-cluster --region=europe-west3

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## Cost Optimization Strategies

### Option 1: Zonal Cluster (Cheaper)
```bash
# Create in single zone instead of region
gcloud container clusters create learning-cluster \
  --zone=europe-west3-a \
  --num-nodes=2 \
  --machine-type=e2-small \
  --disk-size=30

# Cost: 2 x e2-small = ~$30/month (but no HA)
```

### Option 2: Preemptible Nodes
```bash
# Use preemptible nodes (can be terminated anytime)
gcloud container clusters create learning-cluster \
  --zone=europe-west3-a \
  --num-nodes=2 \
  --machine-type=e2-medium \
  --preemptible

# Cost: ~70% cheaper than regular nodes
```

### Option 3: Autopilot Mode
```bash
# Let GKE manage the nodes (pay per pod)
gcloud container clusters create-auto learning-cluster \
  --region=europe-west3

# Cost: Pay only for running pods, no idle node cost
```

### Option 4: Minimal Cluster
```bash
# Single-node zonal cluster (absolute minimum)
gcloud container clusters create learning-cluster \
  --zone=europe-west3-a \
  --num-nodes=1 \
  --machine-type=e2-micro \
  --disk-size=10

# Cost: ~$7/month (very limited resources)
```

## Using the Cluster

### Deploy Sample Application
```bash
# Quick nginx test
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get service nginx --watch

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
```

## Cluster Shutdown

### Option 1: Delete Cluster (Recommended for Cost Savings)

```bash
# Delete the entire cluster
gcloud container clusters delete learning-cluster --region=europe-west3 --quiet

# Or for zonal clusters
gcloud container clusters delete learning-cluster --zone=europe-west3-a --quiet
```

**Deletion Time**: ~3-5 minutes

**What gets deleted**:
- All nodes (compute instances)
- All node pools
- All cluster networking
- Load balancers created by Services
- Persistent disks (if not configured for retention)

**What persists**:
- Container images in Container Registry/Artifact Registry
- Cloud Storage buckets (if created separately)
- VPC networks (if pre-existing)

### Option 2: Resize to Zero Nodes (Partial Cost Savings)

```bash
# Scale down to 0 nodes (keeps cluster configuration)
gcloud container clusters resize learning-cluster \
  --region=europe-west3 \
  --num-nodes=0 \
  --quiet

# Cost: Still pay for cluster management fee (~$0.10/hour)
# Not recommended: Better to delete and recreate
```

### Verify Deletion

```bash
# Confirm cluster is gone
gcloud container clusters list

# Check for any remaining compute instances
gcloud compute instances list --filter="name~learning-cluster"

# Check for orphaned disks
gcloud compute disks list --filter="name~learning-cluster"

# Check for orphaned load balancers
gcloud compute forwarding-rules list
gcloud compute target-pools list
```

### Clean Up Orphaned Resources

```bash
# Sometimes load balancers persist if not deleted properly
# List and delete manually if needed
gcloud compute forwarding-rules list
gcloud compute forwarding-rules delete RULE_NAME --region=REGION

# Delete orphaned disks (if any)
gcloud compute disks list
gcloud compute disks delete DISK_NAME --zone=ZONE
```

## Cluster Lifecycle Timeline

### Demo Session (What We Did)

| Time | Action | Status |
|------|--------|--------|
| 15:47 | Enabled APIs | ✓ Complete |
| 15:48 | Created cluster | ✓ Complete (~5 min) |
| 15:53 | Configured kubectl | ✓ Complete |
| 15:54 | Verified cluster | ✓ Complete |
| 15:55 | Created documentation | ✓ Complete |
| 16:00 | Deleted cluster | ✓ Complete (~3 min) |

**Total Runtime**: ~13 minutes
**Cost Incurred**: ~$0.35 (cluster ran for ~10 minutes)

## Best Practices for Learning

### 1. Create When Needed
```bash
# Don't leave clusters running overnight
# Create fresh clusters for each learning session
```

### 2. Set Budget Alerts
```bash
# Set up billing alerts in GCP Console
# Navigation: Billing → Budgets & alerts
# Recommended: Alert at 50%, 90%, 100% of monthly budget
```

### 3. Use Startup Scripts
```bash
# Save your cluster configuration
# Create script: create-cluster.sh
gcloud container clusters create learning-cluster \
  --zone=europe-west3-a \
  --num-nodes=1 \
  --machine-type=e2-small
```

### 4. Bookmark Deletion Command
```bash
# Keep handy for quick shutdown
alias gke-delete='gcloud container clusters delete learning-cluster --zone=europe-west3-a --quiet'
```

### 5. Use Cloud Shell
```bash
# GCP Cloud Shell is free with 50 hours/week
# Pre-installed with gcloud, kubectl, everything you need
# Access: https://shell.cloud.google.com
```

## Cost Comparison

| Configuration | Monthly Cost | Best For |
|---------------|--------------|----------|
| 1 x e2-micro (zonal) | ~$7 | Absolute minimum testing |
| 2 x e2-small (zonal) | ~$30 | Basic learning |
| 2 x e2-medium (zonal) | ~$60 | Comfortable testing |
| 6 x e2-medium (regional) | ~$162 | HA setup (what we created) |
| Autopilot (minimal) | ~$20-50 | Production-like, variable cost |

**For demo/learning**: Use zonal clusters with e2-small or e2-micro to minimize costs

## Recovery

### Recreate Cluster
```bash
# Use the same commands from creation
gcloud container clusters create learning-cluster \
  --region=europe-west3 \
  --num-nodes=2 \
  --machine-type=e2-medium

# Get credentials again
gcloud container clusters get-credentials learning-cluster --region=europe-west3
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
gcloud container clusters create CLUSTER_NAME [OPTIONS]
gcloud container clusters list
gcloud container clusters describe CLUSTER_NAME
gcloud container clusters delete CLUSTER_NAME --quiet

# COST MONITORING
gcloud compute instances list --format="table(name,machineType,zone,status)"
gcloud compute disks list
gcloud billing accounts list

# QUOTA CHECK
gcloud compute project-info describe --project=PROJECT_ID

# CLEANUP
gcloud container clusters delete CLUSTER_NAME --quiet
gcloud compute disks delete DISK_NAME --zone=ZONE
gcloud compute forwarding-rules delete RULE_NAME --region=REGION
```

## Troubleshooting

### Cluster Won't Delete
```bash
# Force delete after 10 minutes
gcloud container clusters delete learning-cluster \
  --region=europe-west3 \
  --quiet \
  --timeout=600

# Check for stuck resources
gcloud compute operations list --filter="status!=DONE"
```

### Orphaned Load Balancers
```bash
# These can continue charging
# List all forwarding rules
gcloud compute forwarding-rules list

# Delete manually
gcloud compute forwarding-rules delete LB_NAME --region=REGION --quiet
```

### Billing Concerns
```bash
# View current month costs
gcloud billing accounts list

# Check resource usage (via Console)
# Navigation: Billing → Reports
```

## Summary

**Key Takeaway**: For learning and demo purposes:
1. Create cluster when needed
2. Use smallest viable size (zonal + e2-small/e2-micro)
3. **ALWAYS delete when done** (most important!)
4. Set billing alerts
5. Verify deletion completed

**Total cost for this demo session**: ~$0.35 (10 minutes of runtime)

**If left running**: Would cost ~$162/month

**Savings**: 99.8% by deleting immediately after use
