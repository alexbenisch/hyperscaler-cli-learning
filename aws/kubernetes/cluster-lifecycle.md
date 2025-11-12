# EKS Cluster Lifecycle Management

This document covers the complete lifecycle of creating, using, and destroying an EKS cluster for cost-effective learning.

## Cluster Creation

### Prerequisites
1. AWS CLI installed and configured
2. eksctl installed
3. kubectl installed
4. Active AWS account with appropriate permissions
5. IAM permissions for EKS, EC2, VPC, CloudFormation, IAM

### Verify Prerequisites
```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check eksctl
eksctl version

# Check kubectl
kubectl version --client
```

### Create Cluster with eksctl (Recommended)

#### Basic Cluster
```bash
# Simple cluster with managed node group
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

**Creation Time**: ~15-20 minutes

**What gets created**:
- EKS control plane
- VPC with public and private subnets (2 AZs)
- Internet Gateway + NAT Gateway
- Security groups and route tables
- IAM roles for cluster and nodes
- Managed node group with 2 EC2 instances
- Default add-ons (vpc-cni, kube-proxy, coredns, metrics-server)
- 2 CloudFormation stacks

**Cost**:
- Control plane: $73/month
- 2 x t3.medium: ~$60/month
- NAT Gateway: ~$32/month
- **Total**: ~$165/month

#### Create with Config File
```bash
# Create cluster config file
cat > cluster-config.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: learning-eks-cluster
  region: us-east-1

managedNodeGroups:
  - name: standard-workers
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
    volumeSize: 20
    ssh:
      allow: false
    labels:
      role: worker
    tags:
      environment: learning
      managed-by: eksctl
EOF

# Create cluster from config
eksctl create cluster -f cluster-config.yaml
```

### Get Credentials
```bash
# eksctl automatically configures kubectl during creation
# But you can manually update kubeconfig:
aws eks update-kubeconfig \
  --name learning-eks-cluster \
  --region us-east-1

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

## Cost Optimization Strategies

### Option 1: Smaller Instance Types
```bash
# Use t3.small instead of t3.medium
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --node-type t3.small \
  --nodes 2

# Cost savings: ~$30/month vs ~$60/month for nodes
# Total: ~$135/month (control plane + nodes + networking)
```

### Option 2: Single Availability Zone
```bash
# Use specific zones to reduce NAT Gateway costs
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --zones us-east-1a \
  --node-type t3.small \
  --nodes 2

# Cost savings: 1 NAT gateway instead of 2
# Total: ~$103/month
```

### Option 3: Spot Instances
```bash
# Use EC2 Spot instances (can be interrupted)
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --managed \
  --spot \
  --instance-types t3.small,t3.medium \
  --nodes 2

# Cost savings: ~60-90% off on-demand pricing for nodes
# Total: ~$95/month (highly variable)
```

### Option 4: Fargate (Serverless)
```bash
# Use Fargate for pod-level billing
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --fargate

# Cost: Pay per pod vCPU/memory (no idle costs)
# Good for: Intermittent workloads
# Note: More expensive for continuous workloads
```

### Option 5: Minimal Configuration (Not Recommended for Production)
```bash
# Absolute minimum for testing
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --zones us-east-1a \
  --node-type t3.micro \
  --nodes 1

# Cost: ~$85/month
# Warning: Very limited resources, may not run many pods
```

## Using the Cluster

### Deploy Sample Application
```bash
# Quick nginx test
kubectl create deployment nginx --image=nginx:latest

# Expose with LoadBalancer (creates AWS ELB)
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Wait for LoadBalancer (takes 2-3 minutes)
kubectl get service nginx --watch

# Get LoadBalancer DNS
LB_DNS=$(kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test (may need to wait for DNS propagation)
curl http://$LB_DNS

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

# Check EKS cluster status
aws eks describe-cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}'

# Check node group status
aws eks describe-nodegroup \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1 \
  --query 'nodegroup.{Status:status,DesiredSize:scalingConfig.desiredSize}'
```

### View CloudFormation Stacks
```bash
# List CloudFormation stacks for your cluster
aws cloudformation list-stacks \
  --region us-east-1 \
  --query "StackSummaries[?contains(StackName, 'learning-eks-cluster') && StackStatus!='DELETE_COMPLETE'].{Name:StackName,Status:StackStatus}" \
  --output table

# View stack resources
aws cloudformation describe-stack-resources \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1
```

## Cluster Shutdown

### Option 1: Delete Cluster (Recommended)

**Using eksctl (Easiest)**:
```bash
# Delete entire cluster and all resources
eksctl delete cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --wait

# This will:
# - Delete all Kubernetes LoadBalancer services (and AWS ELBs)
# - Delete the node group
# - Delete the control plane
# - Delete VPC, subnets, gateways, route tables
# - Delete both CloudFormation stacks
# - Clean up kubeconfig
```

**Deletion Time**: ~10-15 minutes

**Using AWS CLI (Manual)**:
```bash
# 1. Delete all LoadBalancer services first
kubectl get svc --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.type=="LoadBalancer") | .metadata.name' | \
  xargs -I {} kubectl delete svc {}

# 2. Delete node group
aws eks delete-nodegroup \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1

# Wait for node group deletion (~5 min)
aws eks wait nodegroup-deleted \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1

# 3. Delete cluster
aws eks delete-cluster \
  --name learning-eks-cluster \
  --region us-east-1

# Wait for cluster deletion (~5 min)
aws eks wait cluster-deleted \
  --name learning-eks-cluster \
  --region us-east-1

# 4. Manually delete VPC and related resources (tedious!)
# Not recommended - use eksctl instead
```

### Option 2: Scale to Zero Nodes (Partial Savings)
```bash
# Scale node group to 0
eksctl scale nodegroup \
  --cluster=learning-eks-cluster \
  --region=us-east-1 \
  --name=standard-workers \
  --nodes=0

# Cost: Still pay for control plane ($73/month)
# Savings: ~55% (nodes + reduced NAT usage)
# Use case: Short breaks while keeping cluster config
# Note: Better to delete and recreate for longer periods
```

### Verify Deletion

```bash
# Confirm cluster is gone
aws eks list-clusters --region us-east-1

# Verify no EKS-related EC2 instances
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:eks:cluster-name,Values=learning-eks-cluster" \
  --query 'Reservations[].Instances[].InstanceId'

# Check for orphaned EBS volumes
aws ec2 describe-volumes \
  --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/learning-eks-cluster,Values=owned" \
  --query 'Volumes[].VolumeId'

# Check for orphaned load balancers
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `learning-eks`)].LoadBalancerArn'

aws elb describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `learning-eks`)].LoadBalancerName'

# Check CloudFormation stacks
aws cloudformation list-stacks \
  --region us-east-1 \
  --query "StackSummaries[?contains(StackName, 'learning-eks-cluster') && StackStatus!='DELETE_COMPLETE']"
```

### Clean Up Orphaned Resources

```bash
# Delete orphaned load balancers
# Classic Load Balancer
aws elb delete-load-balancer \
  --load-balancer-name LB_NAME \
  --region us-east-1

# Application/Network Load Balancer
aws elbv2 delete-load-balancer \
  --load-balancer-arn LB_ARN \
  --region us-east-1

# Delete orphaned EBS volumes
aws ec2 delete-volume \
  --volume-id vol-xxxxx \
  --region us-east-1

# Delete orphaned security groups (after other resources)
aws ec2 delete-security-group \
  --group-id sg-xxxxx \
  --region us-east-1

# Force delete stuck CloudFormation stack
aws cloudformation delete-stack \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1
```

## Cluster Lifecycle Timeline

### Demo Session (What We Did)

| Time (UTC) | Action | Duration | Status |
|------------|--------|----------|--------|
| 16:04 | Started cluster creation | - | ✓ |
| 16:04-16:13 | Control plane provisioning | ~9 min | ✓ |
| 16:13-16:14 | Add-ons installation | ~1 min | ✓ |
| 16:14-16:18 | Node group deployment | ~4 min | ✓ |
| 16:18 | Cluster ready | **14 min total** | ✓ |
| 16:18 | kubectl configured | - | ✓ |
| 16:19-16:26 | Deployed nginx | - | ✓ |
| 16:26 | Started cluster deletion | - | ✓ |
| 16:26-16:27 | Load balancer cleanup | ~30 sec | ✓ |
| 16:27-16:34 | Node group deletion | ~7 min | ✓ |
| 16:34-16:36 | Control plane deletion | ~2 min | ✓ |
| 16:36 | All resources deleted | **10 min total** | ✓ |

**Total Runtime**: ~32 minutes (14 min creation + 8 min usage + 10 min deletion)

**Cost Incurred**: ~$1.50 (32 minutes of cluster + nodes + networking)

## Best Practices for Learning

### 1. Always Delete When Done
```bash
# Most important rule: Delete immediately after learning
eksctl delete cluster --name learning-eks-cluster --region us-east-1

# Cost if left running: ~$165/month
# Cost of 1-hour session: ~$0.23
# Savings from deleting: 99.9%
```

### 2. Set Budget Alerts
```bash
# Set up AWS Budget via Console
# Navigation: AWS Budgets → Create budget
# Recommended: Alert at $10, $25, $50

# Or via CLI
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json
```

### 3. Use Startup Scripts
```bash
# Save your cluster configuration
# File: create-cluster.sh
#!/bin/bash
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --zones us-east-1a \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3

# Make executable
chmod +x create-cluster.sh
```

### 4. Bookmark Deletion Command
```bash
# Add alias to ~/.bashrc or ~/.zshrc
alias eks-delete='eksctl delete cluster --name learning-eks-cluster --region us-east-1'

# Quick cleanup
eks-delete
```

### 5. Tag Resources
```bash
# Add tags for tracking
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --tags environment=learning,owner=YOUR_NAME,project=k8s-learning
```

### 6. Monitor Costs
```bash
# Check estimated costs via AWS Cost Explorer
echo "https://console.aws.amazon.com/cost-management/home#/cost-explorer"

# Or use CLI
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-11-30 \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter file://filter.json
```

## Cost Comparison

| Configuration | Setup Cost | Monthly Cost | Creation Time | Best For |
|---------------|------------|--------------|---------------|----------|
| Minimal (1 x t3.micro, single AZ) | ~$0.12/hr | ~$85 | ~12 min | Absolute minimum |
| Small (2 x t3.small, single AZ) | ~$0.14/hr | ~$103 | ~14 min | **Learning** ⭐ |
| Standard (2 x t3.medium, multi-AZ) | ~$0.23/hr | ~$165 | ~15 min | Realistic testing |
| Spot (2 x t3.small spot, single AZ) | ~$0.08/hr | ~$60 | ~14 min | Cost-sensitive dev |
| Fargate | Variable | $20-100 | ~8 min | On-demand workloads |

**For demo/learning**: Use **2 x t3.small in single AZ** to balance cost and usability

**Estimated cost for 1-hour learning session**: ~$0.14

## Recovery and Recreation

### Recreate Cluster
```bash
# Use same command from creation
eksctl create cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --zones us-east-1a \
  --node-type t3.small \
  --nodes 2

# Get credentials
aws eks update-kubeconfig \
  --name learning-eks-cluster \
  --region us-east-1
```

### Restore Applications
```bash
# If you saved manifests
kubectl apply -f my-app.yaml

# Or redeploy from scratch
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

### Export Cluster Configuration
```bash
# Export current cluster config
eksctl get cluster learning-eks-cluster \
  --region us-east-1 \
  -o yaml > cluster-backup.yaml

# Use to recreate later
eksctl create cluster -f cluster-backup.yaml
```

## Understanding the Creation Process

### Phase 1: CloudFormation Stack (Control Plane)
```bash
# Watch stack creation in real-time
aws cloudformation describe-stack-events \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1 \
  --max-items 10
```

**Resources created** (~9 minutes):
- VPC (192.168.0.0/16)
- 4 subnets (2 public, 2 private)
- Internet Gateway
- NAT Gateway(s)
- Route tables (4)
- Security groups (2)
- IAM roles (cluster role)
- EKS cluster

### Phase 2: Add-ons Installation
```bash
# Watch add-ons being created
aws eks list-addons \
  --cluster-name learning-eks-cluster \
  --region us-east-1

# Check add-on status
aws eks describe-addon \
  --cluster-name learning-eks-cluster \
  --addon-name vpc-cni \
  --region us-east-1
```

**Add-ons installed** (~1 minute):
- vpc-cni (AWS CNI plugin)
- kube-proxy (network proxy)
- coredns (DNS)
- metrics-server (metrics collection)

### Phase 3: Node Group Deployment
```bash
# Watch node group creation
aws eks describe-nodegroup \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1 \
  --query 'nodegroup.status'

# Watch nodes join cluster
kubectl get nodes --watch
```

**Resources created** (~4 minutes):
- Auto Scaling Group
- Launch Template
- 2 EC2 instances (t3.medium)
- IAM instance profile
- Nodes join cluster

## Troubleshooting

### Cluster Creation Failures

**CloudFormation Stack Stuck**:
```bash
# View failed resources
aws cloudformation describe-stack-events \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Common issues:
# - Insufficient IAM permissions
# - VPC quota exceeded
# - No available IP addresses in subnet
```

**Node Group Not Creating**:
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1

# Common issues:
# - EC2 instance quota exceeded
# - Insufficient subnet capacity
# - IAM role issues
```

### Deletion Issues

**Cluster Won't Delete**:
```bash
# Most common: LoadBalancers not deleted
kubectl get svc --all-namespaces -o wide

# Delete all LoadBalancer services manually
kubectl delete svc SERVICE_NAME -n NAMESPACE

# Force delete stuck stack
aws cloudformation delete-stack \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1
```

**Orphaned Resources**:
```bash
# Find and delete orphaned ENIs (network interfaces)
aws ec2 describe-network-interfaces \
  --region us-east-1 \
  --filters "Name=description,Values=*EKS*learning-eks-cluster*" \
  --query 'NetworkInterfaces[].NetworkInterfaceId'

# Delete ENI
aws ec2 delete-network-interface \
  --network-interface-id eni-xxxxx \
  --region us-east-1
```

## Summary

**Key Takeaways for Learning**:

1. **Creation**: ~15-20 minutes (slower than GKE/AKS)
2. **Deletion**: ~10-15 minutes
3. **Cost**: Minimum ~$85/month (control plane + minimal nodes)
4. **Best practice**: **Delete immediately** after each session
5. **Savings**: Delete vs leaving running = 99.9% cost reduction

**Comparison to other providers**:
- **EKS**: More complex, slower, more expensive, more flexible
- **GKE**: Faster (~5 min), simpler, cheaper, less control
- **AKS**: Middle ground (~8 min), has start/stop feature

**Critical reminder**: Unlike GKE/AKS, EKS has no "pause" option. You must delete the cluster to stop all charges. Control plane alone costs $73/month!

**Total cost for this demo session**: ~$1.50 (32 minutes)

**If left running for a month**: ~$165

**Savings from immediate deletion**: 99.1%
