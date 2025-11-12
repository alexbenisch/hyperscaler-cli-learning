# EKS (Amazon Elastic Kubernetes Service) Setup

This directory contains information about the EKS cluster setup for learning purposes.

## Prerequisites

### Required Tools
1. **AWS CLI** - AWS Command Line Interface
2. **eksctl** - EKS cluster management tool
3. **kubectl** - Kubernetes command-line tool

### Installation (Arch Linux)
```bash
# AWS CLI
yay -S aws-cli-v2

# eksctl
yay -S eksctl

# kubectl (if not already installed)
sudo pacman -S kubectl
```

### AWS Configuration
```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

## Cluster Architecture

EKS clusters consist of:
- **Control Plane**: Managed by AWS (runs in AWS-managed account)
- **Data Plane**: Worker nodes (EC2 instances) in your VPC
- **Networking**: VPC, subnets, security groups, NAT gateways
- **Add-ons**: vpc-cni, kube-proxy, coredns, metrics-server

## Quick Start

### Create Cluster (Simple)
```bash
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

**Creation Time**: 15-20 minutes
**Cost**: 2 x t3.medium = ~$60/month

### Get Credentials
```bash
# eksctl automatically configures kubectl, but you can manually update:
aws eks update-kubeconfig --name learning-eks-cluster --region us-east-1

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Delete Cluster
```bash
eksctl delete cluster --name learning-eks-cluster --region us-east-1
```

**Deletion Time**: 10-15 minutes

## Cluster Details

### Network Architecture

EKS creates the following networking resources:

**VPC**:
- CIDR: 192.168.0.0/16
- Spans 2-3 availability zones

**Subnets** (per AZ):
- Public subnet: For load balancers and NAT gateways
- Private subnet: For worker nodes

**Gateways**:
- Internet Gateway: For public subnet internet access
- NAT Gateway(s): For private subnet outbound traffic

**Security Groups**:
- Cluster security group: Control plane ↔ nodes communication
- Node security group: Inter-node and pod communication

### Default Add-ons

When creating with eksctl, these add-ons are installed automatically:

1. **vpc-cni**: AWS's CNI plugin for pod networking
2. **kube-proxy**: Network proxy for Kubernetes services
3. **coredns**: DNS server for service discovery
4. **metrics-server**: Resource metrics collection

## Cluster Access

### Basic Commands
```bash
# Check cluster info
kubectl cluster-info

# List nodes with details
kubectl get nodes -o wide

# List all pods across namespaces
kubectl get pods -A

# Get cluster details via AWS CLI
aws eks describe-cluster --name learning-eks-cluster --region us-east-1

# Get cluster details via eksctl
eksctl get cluster --name learning-eks-cluster --region us-east-1
```

### View Cluster in Console
```bash
# Get console URL
echo "https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/learning-eks-cluster"
```

## Cluster Management

### Scale Node Group
```bash
# Scale to different number of nodes
eksctl scale nodegroup \
  --cluster=learning-eks-cluster \
  --region=us-east-1 \
  --name=standard-workers \
  --nodes=3 \
  --nodes-min=1 \
  --nodes-max=5

# Or using AWS CLI
aws eks update-nodegroup-config \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --scaling-config minSize=1,maxSize=5,desiredSize=3
```

### Upgrade Cluster
```bash
# List available versions
aws eks describe-addon-versions --kubernetes-version 1.32

# Upgrade control plane
eksctl upgrade cluster \
  --name=learning-eks-cluster \
  --region=us-east-1 \
  --version=1.33

# Upgrade node group
eksctl upgrade nodegroup \
  --name=standard-workers \
  --cluster=learning-eks-cluster \
  --region=us-east-1
```

### Manage Add-ons
```bash
# List installed add-ons
aws eks list-addons --cluster-name learning-eks-cluster --region us-east-1

# Describe specific add-on
aws eks describe-addon \
  --cluster-name learning-eks-cluster \
  --addon-name vpc-cni \
  --region us-east-1

# Update add-on
aws eks update-addon \
  --cluster-name learning-eks-cluster \
  --addon-name vpc-cni \
  --addon-version v1.18.0-eksbuild.1 \
  --region us-east-1
```

## Cost Information

### Basic Cluster Cost Breakdown

**EKS Control Plane**: $0.10/hour = **$73/month** (fixed cost)

**Worker Nodes** (variable based on instance type):
- 2 x t3.medium: ~$60/month
- 2 x t3.small: ~$30/month
- 2 x t3.micro: ~$15/month

**Networking**:
- NAT Gateway: ~$32/month per gateway
- Data transfer: Variable
- Load Balancers: ~$16/month per ALB/NLB

**Storage**:
- EBS volumes (node disks): Included in EC2 pricing
- Persistent volumes: ~$0.10/GB/month (gp3)

**Example Total Costs**:
- Minimal cluster (2 x t3.small): ~$175/month
- Standard cluster (2 x t3.medium): ~$205/month
- With NAT Gateway redundancy: Add $32/month per AZ

### Cost Optimization Tips
1. **Use eksctl for simpler networking** (fewer NAT gateways)
2. **Stop/terminate nodes when not in use** (but keep control plane)
3. **Use Spot instances for dev/test workloads**
4. **Delete load balancers when not needed**
5. **Use Fargate for on-demand pod compute** (no idle node costs)
6. **Delete the entire cluster when done** (most important!)

### Fargate Profile (Serverless Nodes)
```bash
# Create Fargate profile
eksctl create fargateprofile \
  --cluster learning-eks-cluster \
  --region us-east-1 \
  --name fp-default \
  --namespace default

# Cost: Pay per pod vCPU-hour and memory-hour (no idle costs)
```

## Deploy Sample Application

### Deploy nginx
```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Expose with LoadBalancer (creates AWS ELB/ALB)
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check service (wait for EXTERNAL-IP, takes 2-3 minutes)
kubectl get service nginx --watch

# Get the LoadBalancer DNS
kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test (wait for DNS propagation)
curl http://$(kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Clean up
kubectl delete service nginx
kubectl delete deployment nginx
```

### Test from Inside Cluster
```bash
# Run a temporary pod with curl
kubectl run test-curl \
  --image=curlimages/curl \
  --rm -it --restart=Never \
  -- curl -I http://nginx

# This tests internal cluster networking
```

### Deploy with Manifest
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
        image: public.ecr.aws/nginx/nginx:latest
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

## Advanced Features

### Enable Auto-scaling
```bash
# Enable cluster autoscaler
eksctl create iamserviceaccount \
  --cluster=learning-eks-cluster \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::aws:policy/AutoScalingFullAccess \
  --approve

# Deploy cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

### CloudFormation Stacks

EKS uses CloudFormation for infrastructure management:

```bash
# List all stacks for your cluster
aws cloudformation list-stacks \
  --region us-east-1 \
  --query "StackSummaries[?contains(StackName, 'learning-eks-cluster')]"

# View stack resources
aws cloudformation describe-stack-resources \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1
```

## Troubleshooting

### Authentication Issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Re-fetch credentials
aws eks update-kubeconfig \
  --name learning-eks-cluster \
  --region us-east-1

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

# Check node group status via AWS CLI
aws eks describe-nodegroup \
  --cluster-name learning-eks-cluster \
  --nodegroup-name standard-workers \
  --region us-east-1

# View node logs via EC2
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=learning-eks-cluster" \
  --region us-east-1
```

### Pod Networking Issues
```bash
# Check VPC CNI pods
kubectl get pods -n kube-system -l k8s-app=aws-node

# View CNI logs
kubectl logs -n kube-system -l k8s-app=aws-node

# Check security groups
aws eks describe-cluster \
  --name learning-eks-cluster \
  --region us-east-1 \
  --query 'cluster.resourcesVpcConfig.{SecurityGroups:securityGroupIds,Subnets:subnetIds}'
```

### Load Balancer Issues
```bash
# Check service
kubectl describe service SERVICE_NAME

# View AWS load balancers
aws elbv2 describe-load-balancers --region us-east-1
aws elb describe-load-balancers --region us-east-1

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN \
  --region us-east-1
```

### CloudFormation Stack Stuck
```bash
# View stack events
aws cloudformation describe-stack-events \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1 \
  --max-items 20

# Check for failed resources
aws cloudformation describe-stack-resources \
  --stack-name eksctl-learning-eks-cluster-cluster \
  --region us-east-1 \
  --query "StackResources[?ResourceStatus=='CREATE_FAILED']"
```

## Monitoring and Logging

### CloudWatch Container Insights
```bash
# Enable Container Insights
eksctl utils update-cluster-logging \
  --cluster=learning-eks-cluster \
  --region=us-east-1 \
  --enable-types=all

# View logs in CloudWatch
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups"
```

### Metrics
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# View metrics via metrics-server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

## JSON Output Colorization

EKS/AWS CLI outputs JSON by default. For better readability:

### Using jq
```bash
# Install jq
sudo pacman -S jq

# Pipe AWS commands through jq
aws eks describe-cluster --name learning-eks-cluster --region us-east-1 | jq '.'

# Extract specific fields with color
aws eks describe-cluster --name learning-eks-cluster --region us-east-1 | \
  jq '.cluster | {name, status, version, endpoint}'

# List node groups
aws eks list-nodegroups --cluster-name learning-eks-cluster --region us-east-1 | jq -C '.'
```

### Using bat
```bash
# Install bat for syntax highlighting
sudo pacman -S bat

# Use as JSON viewer
aws eks describe-cluster --name learning-eks-cluster --region us-east-1 | bat -l json
```

### AWS CLI Built-in Options
```bash
# Table output (no color, but more readable)
aws eks list-clusters --region us-east-1 --output table

# Enable AWS CLI auto-prompt
export AWS_CLI_AUTO_PROMPT=on-partial
```

## Additional Resources

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [eksctl Documentation](https://eksctl.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [Cluster Lifecycle Management](cluster-lifecycle.md) - Detailed guide on creating and deleting clusters

## Cluster History

### Demo Session - 2025-11-12
**Created**: 2025-11-12 ~16:04 UTC
**Deleted**: 2025-11-12 ~16:36 UTC
**Runtime**: ~32 minutes (14 min creation + 10 min usage + 10 min deletion)
**Cost**: ~$1.50

**Configuration**:
- Region: us-east-1 (Virginia, USA)
- Nodes: 2 x t3.medium (2 vCPU, 4GB RAM each)
- Node Group: Managed node group (standard-workers)
- Kubernetes Version: 1.32
- Purpose: Learning and experimentation with EKS
- Status: **DELETED** (cluster no longer exists)

**Key Learnings**:
- EKS creation is slower than GKE/AKS (~15-20 min vs ~5 min)
- Uses CloudFormation for infrastructure management (IaC approach)
- eksctl dramatically simplifies cluster creation vs raw AWS CLI
- Requires VPC, subnets, NAT gateways (more complex networking)
- LoadBalancer DNS takes 2-3 minutes to propagate
- Control plane always costs $73/month even when idle
- **Always delete clusters after demo/testing to avoid ongoing costs**

**Resources Created**:
- EKS cluster control plane
- 2 CloudFormation stacks (cluster + node group)
- VPC with 4 subnets (2 public, 2 private) across 2 AZs
- Internet Gateway + NAT Gateway
- Route tables and security groups
- 2 EC2 t3.medium instances
- IAM roles and policies
- EKS add-ons (vpc-cni, kube-proxy, coredns, metrics-server)

To recreate this cluster, see the commands in [cluster-lifecycle.md](cluster-lifecycle.md)
