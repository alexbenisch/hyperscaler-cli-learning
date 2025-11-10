# AWS CLI Learning

Learn to use the `aws` CLI to manage Amazon Web Services infrastructure.

## 📋 Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Basic Commands](#basic-commands)
- [Compute (EC2)](#compute-ec2)
- [Storage (S3, EBS)](#storage)
- [Networking](#networking)
- [Kubernetes (EKS)](#kubernetes-eks)
- [Example Projects](#example-projects)

## Installation

### Linux

```bash
# Download and install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### macOS

```bash
# Using Homebrew
brew install awscli

# Or download package
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify
aws --version
```

## Configuration

```bash
# Configure with access keys
# Get keys from: AWS Console → IAM → Users → Security credentials
aws configure

# Enter:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json

# Configure named profile
aws configure --profile production
aws configure --profile dev

# List profiles
cat ~/.aws/credentials

# Use specific profile
aws s3 ls --profile production
export AWS_PROFILE=production

# Test configuration
aws sts get-caller-identity
```

## Basic Commands

### General

```bash
# List all services
aws help

# Get help for specific service
aws ec2 help
aws ec2 describe-instances help

# Set output format
aws ec2 describe-instances --output json
aws ec2 describe-instances --output table
aws ec2 describe-instances --output text

# Use JMESPath queries
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'

# List regions
aws ec2 describe-regions --output table

# Set default region
aws configure set region eu-central-1
```

## Compute (EC2)

### List Available Resources

```bash
# List AMIs (Amazon Linux 2)
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table | head -20

# List instance types
aws ec2 describe-instance-types \
  --filters "Name=instance-type,Values=t*.micro,t*.small" \
  --query 'InstanceTypes[*].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]' \
  --output table

# List availability zones
aws ec2 describe-availability-zones --output table
```

### Create and Manage Instances

```bash
# Create security group
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Web server security group"

# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
  --group-name web-sg \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Create key pair
aws ec2 create-key-pair \
  --key-name my-key \
  --query 'KeyMaterial' \
  --output text > my-key.pem
chmod 400 my-key.pem

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name my-key \
  --security-groups web-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server}]'

# Launch with user data
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name my-key \
  --security-groups web-sg \
  --user-data file://cloud-init.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server}]'

# List instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Get instance details
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Get instance public IP
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Instance Operations

```bash
# Start instance
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Stop instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Reboot instance
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0

# Terminate instance
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids i-1234567890abcdef0

# Connect via SSM (no SSH key needed)
aws ssm start-session --target i-1234567890abcdef0

# Get console output (for debugging)
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

## Storage

### S3 (Object Storage)

```bash
# Create bucket
aws s3 mb s3://my-unique-bucket-name

# List buckets
aws s3 ls

# Upload file
aws s3 cp myfile.txt s3://my-bucket/
aws s3 cp myfile.txt s3://my-bucket/folder/

# Upload directory
aws s3 cp ./mydir s3://my-bucket/mydir --recursive

# Download file
aws s3 cp s3://my-bucket/myfile.txt .

# Download directory
aws s3 cp s3://my-bucket/mydir ./mydir --recursive

# List objects
aws s3 ls s3://my-bucket/
aws s3 ls s3://my-bucket/folder/ --recursive

# Sync directories
aws s3 sync ./local-dir s3://my-bucket/remote-dir
aws s3 sync s3://my-bucket/remote-dir ./local-dir

# Delete file
aws s3 rm s3://my-bucket/myfile.txt

# Delete directory
aws s3 rm s3://my-bucket/folder --recursive

# Delete bucket
aws s3 rb s3://my-bucket --force  # --force deletes all objects first

# Set bucket policy (public read)
aws s3api put-bucket-policy \
  --bucket my-bucket \
  --policy file://policy.json

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled
```

### EBS (Block Storage)

```bash
# Create volume
aws ec2 create-volume \
  --size 10 \
  --availability-zone us-east-1a \
  --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=my-volume}]'

# List volumes
aws ec2 describe-volumes \
  --query 'Volumes[*].[VolumeId,Size,State,AvailabilityZone]' \
  --output table

# Attach volume
aws ec2 attach-volume \
  --volume-id vol-1234567890abcdef0 \
  --instance-id i-1234567890abcdef0 \
  --device /dev/sdf

# Detach volume
aws ec2 detach-volume --volume-id vol-1234567890abcdef0

# Create snapshot
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "My backup snapshot"

# List snapshots
aws ec2 describe-snapshots --owner-ids self

# Delete snapshot
aws ec2 delete-snapshot --snapshot-id snap-1234567890abcdef0

# Delete volume
aws ec2 delete-volume --volume-id vol-1234567890abcdef0
```

## Networking

### VPC

```bash
# Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'

# Create subnet
aws ec2 create-subnet \
  --vpc-id vpc-1234567890abcdef0 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet}]'

# Create internet gateway
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw}]'

# Attach internet gateway
aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-1234567890abcdef0 \
  --vpc-id vpc-1234567890abcdef0

# Create route table
aws ec2 create-route-table \
  --vpc-id vpc-1234567890abcdef0 \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]'

# Add route to internet
aws ec2 create-route \
  --route-table-id rtb-1234567890abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-1234567890abcdef0

# Associate route table with subnet
aws ec2 associate-route-table \
  --route-table-id rtb-1234567890abcdef0 \
  --subnet-id subnet-1234567890abcdef0

# List VPCs
aws ec2 describe-vpcs --output table

# List subnets
aws ec2 describe-subnets --output table
```

### Load Balancers

```bash
# Create application load balancer
aws elbv2 create-load-balancer \
  --name my-alb \
  --subnets subnet-12345 subnet-67890 \
  --security-groups sg-12345

# Create target group
aws elbv2 create-target-group \
  --name my-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-1234567890abcdef0

# Register targets
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-1234567890abcdef0

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:...

# List load balancers
aws elbv2 describe-load-balancers --output table
```

## Kubernetes (EKS)

```bash
# Create EKS cluster
aws eks create-cluster \
  --name my-cluster \
  --role-arn arn:aws:iam::123456789012:role/EKSClusterRole \
  --resources-vpc-config subnetIds=subnet-12345,subnet-67890,securityGroupIds=sg-12345

# Wait for cluster to be active
aws eks wait cluster-active --name my-cluster

# Update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# List clusters
aws eks list-clusters

# Describe cluster
aws eks describe-cluster --name my-cluster

# Create node group
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodes \
  --subnets subnet-12345 subnet-67890 \
  --instance-types t3.medium \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --node-role arn:aws:iam::123456789012:role/EKSNodeRole

# List node groups
aws eks list-nodegroups --cluster-name my-cluster

# Delete node group
aws eks delete-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes

# Delete cluster
aws eks delete-cluster --name my-cluster
```

## Example Projects

### Example 1: Deploy Web Server with ALB

```bash
#!/bin/bash
# deploy-web-with-alb.sh

# Variables
VPC_CIDR="10.0.0.0/16"
SUBNET1_CIDR="10.0.1.0/24"
SUBNET2_CIDR="10.0.2.0/24"
AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=web-vpc

# Create subnets in different AZs
SUBNET1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET1_CIDR --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
SUBNET2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET2_CIDR --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# Create and attach internet gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create security group
SG_ID=$(aws ec2 create-security-group --group-name web-sg --description "Web server SG" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launch instances
for SUBNET in $SUBNET1 $SUBNET2; do
  aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --subnet-id $SUBNET \
    --security-group-ids $SG_ID \
    --user-data '#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname)" > /var/www/html/index.html'
done

echo "Web servers deployed in VPC: $VPC_ID"
```

### Example 2: S3 Static Website Hosting

```bash
#!/bin/bash
# setup-s3-website.sh

BUCKET_NAME="my-website-$(date +%s)"

# Create bucket
aws s3 mb s3://$BUCKET_NAME

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME \
  --index-document index.html \
  --error-document error.html

# Set bucket policy for public read
cat > policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
  }]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://policy.json

# Upload website files
echo "<h1>Hello from S3!</h1>" > index.html
aws s3 cp index.html s3://$BUCKET_NAME/

# Get website URL
echo "Website URL: http://$BUCKET_NAME.s3-website-$(aws configure get region).amazonaws.com"
```

### Example 3: Automated Backup Script

```bash
#!/bin/bash
# backup-volumes.sh

# Get all volumes with tag "Backup=true"
VOLUMES=$(aws ec2 describe-volumes \
  --filters "Name=tag:Backup,Values=true" \
  --query 'Volumes[*].VolumeId' \
  --output text)

for VOLUME in $VOLUMES; do
  echo "Creating snapshot for $VOLUME"
  aws ec2 create-snapshot \
    --volume-id $VOLUME \
    --description "Automated backup $(date +%Y-%m-%d)" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=AutoBackup,Value=true}]"
done

# Delete old snapshots (older than 7 days)
CUTOFF_DATE=$(date -d '7 days ago' +%Y-%m-%d)
OLD_SNAPSHOTS=$(aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:AutoBackup,Values=true" \
  --query "Snapshots[?StartTime<='$CUTOFF_DATE'].SnapshotId" \
  --output text)

for SNAPSHOT in $OLD_SNAPSHOTS; do
  echo "Deleting old snapshot: $SNAPSHOT"
  aws ec2 delete-snapshot --snapshot-id $SNAPSHOT
done
```

## Tips and Best Practices

### Cost Optimization

```bash
# List running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType]' \
  --output table

# Stop all development instances after hours
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | xargs aws ec2 stop-instances --instance-ids

# Use Spot instances for non-critical workloads
aws ec2 request-spot-instances \
  --spot-price "0.03" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification file://spot-spec.json
```

### Security

```bash
# Enable MFA for your account (via console)

# Rotate access keys regularly
aws iam create-access-key --user-name myuser
# Update ~/.aws/credentials
aws iam delete-access-key --access-key-id OLD_KEY_ID --user-name myuser

# Use IAM roles instead of access keys for EC2
# Attach role to instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=MyInstanceProfile

# Enable CloudTrail for audit logging
aws cloudtrail create-trail \
  --name my-trail \
  --s3-bucket-name my-audit-bucket
```

### Automation

```bash
# Use AWS CLI with scripts
#!/bin/bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 wait instance-running --instance-ids $INSTANCE_ID
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance ready at: $PUBLIC_IP"

# Use AWS CLI in loops
for REGION in us-east-1 us-west-2 eu-west-1; do
  echo "Checking $REGION..."
  aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
done
```

## Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS CLI on GitHub](https://github.com/aws/aws-cli)

## Pricing

**EC2 (us-east-1):**
- t2.micro: $0.0116/hour (~$8.50/month) - Free tier: 750 hours/month
- t2.small: $0.023/hour (~$16.79/month)
- t3.medium: $0.0416/hour (~$30.37/month)

**S3:**
- Storage: $0.023/GB/month (first 50 TB)
- Requests: $0.0004 per 1,000 PUT requests

**EBS:**
- gp3: $0.08/GB/month
- Snapshots: $0.05/GB/month

Check latest pricing at: https://aws.amazon.com/pricing/
