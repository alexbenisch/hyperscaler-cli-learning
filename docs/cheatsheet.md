# Cloud CLI Cheatsheet

Quick reference for common operations across all cloud providers.

## Server/Instance Management

| Operation | AWS | Azure | GCP | Hetzner | OCI |
|-----------|-----|-------|-----|---------|-----|
| **List instances** | `aws ec2 describe-instances` | `az vm list` | `gcloud compute instances list` | `hcloud server list` | `oci compute instance list` |
| **Create instance** | `aws ec2 run-instances` | `az vm create` | `gcloud compute instances create` | `hcloud server create` | `oci compute instance launch` |
| **Start instance** | `aws ec2 start-instances` | `az vm start` | `gcloud compute instances start` | `hcloud server poweron` | `oci compute instance action --action START` |
| **Stop instance** | `aws ec2 stop-instances` | `az vm stop` | `gcloud compute instances stop` | `hcloud server poweroff` | `oci compute instance action --action STOP` |
| **Delete instance** | `aws ec2 terminate-instances` | `az vm delete` | `gcloud compute instances delete` | `hcloud server delete` | `oci compute instance terminate` |
| **SSH to instance** | `aws ssm start-session` | `az ssh vm` | `gcloud compute ssh` | `ssh root@IP` | `ssh opc@IP` |

## Storage (Object Storage)

| Operation | AWS S3 | Azure Blob | GCP Cloud Storage | Hetzner | OCI Object Storage |
|-----------|--------|------------|-------------------|---------|---------------------|
| **List buckets** | `aws s3 ls` | `az storage container list` | `gsutil ls` | N/A | `oci os bucket list` |
| **Create bucket** | `aws s3 mb s3://name` | `az storage container create` | `gsutil mb gs://name` | N/A | `oci os bucket create` |
| **Upload file** | `aws s3 cp file s3://bucket/` | `az storage blob upload` | `gsutil cp file gs://bucket/` | N/A | `oci os object put` |
| **Download file** | `aws s3 cp s3://bucket/file .` | `az storage blob download` | `gsutil cp gs://bucket/file .` | N/A | `oci os object get` |
| **List objects** | `aws s3 ls s3://bucket/` | `az storage blob list` | `gsutil ls gs://bucket/` | N/A | `oci os object list` |
| **Delete bucket** | `aws s3 rb s3://name` | `az storage container delete` | `gsutil rb gs://name` | N/A | `oci os bucket delete` |

## Kubernetes

| Operation | AWS EKS | Azure AKS | GCP GKE | Hetzner | OCI OKE |
|-----------|---------|-----------|---------|---------|---------|
| **List clusters** | `aws eks list-clusters` | `az aks list` | `gcloud container clusters list` | N/A | `oci ce cluster list` |
| **Create cluster** | `aws eks create-cluster` | `az aks create` | `gcloud container clusters create` | N/A | `oci ce cluster create` |
| **Get credentials** | `aws eks update-kubeconfig` | `az aks get-credentials` | `gcloud container clusters get-credentials` | N/A | `oci ce cluster create-kubeconfig` |
| **Delete cluster** | `aws eks delete-cluster` | `az aks delete` | `gcloud container clusters delete` | N/A | `oci ce cluster delete` |

## Networking

| Operation | AWS | Azure | GCP | Hetzner | OCI |
|-----------|-----|-------|-----|---------|-----|
| **List networks** | `aws ec2 describe-vpcs` | `az network vnet list` | `gcloud compute networks list` | `hcloud network list` | `oci network vcn list` |
| **Create network** | `aws ec2 create-vpc` | `az network vnet create` | `gcloud compute networks create` | `hcloud network create` | `oci network vcn create` |
| **List subnets** | `aws ec2 describe-subnets` | `az network vnet subnet list` | `gcloud compute networks subnets list` | N/A | `oci network subnet list` |

## Identity & Access

| Operation | AWS | Azure | GCP | Hetzner | OCI |
|-----------|-----|-------|-----|---------|-----|
| **List users** | `aws iam list-users` | `az ad user list` | `gcloud iam service-accounts list` | N/A | `oci iam user list` |
| **Current identity** | `aws sts get-caller-identity` | `az account show` | `gcloud auth list` | N/A | `oci iam user list --user-id $(whoami)` |

## General

| Operation | AWS | Azure | GCP | Hetzner | OCI |
|-----------|-----|-------|-----|---------|-----|
| **Configure CLI** | `aws configure` | `az login` | `gcloud init` | `hcloud context create` | `oci setup config` |
| **Set region** | `aws configure set region` | `az configure --defaults location` | `gcloud config set compute/region` | N/A | `oci setup config` |
| **Output format** | `--output json/table/text` | `--output json/table/tsv` | `--format json/yaml/text` | `-o json/table` | `--output json/table` |
| **Version** | `aws --version` | `az --version` | `gcloud version` | `hcloud version` | `oci --version` |
| **Help** | `aws help` | `az --help` | `gcloud help` | `hcloud --help` | `oci --help` |

## Cost Management

| Operation | AWS | Azure | GCP | Hetzner | OCI |
|-----------|-----|-------|-----|---------|-----|
| **View costs** | `aws ce get-cost-and-usage` | `az consumption usage list` | `gcloud billing accounts list` | Console only | `oci usage-api usage-summary` |
| **Set budget** | `aws budgets create-budget` | `az consumption budget create` | `gcloud billing budgets create` | N/A | `oci budget budget create` |

## Common Patterns

### Create a simple web server

**AWS:**
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name my-key \
  --security-group-ids sg-xxx \
  --user-data file://setup.sh
```

**Azure:**
```bash
az vm create \
  --resource-group myRG \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data setup.sh
```

**GCP:**
```bash
gcloud compute instances create my-instance \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=setup.sh
```

**Hetzner:**
```bash
hcloud server create \
  --name my-server \
  --type cx11 \
  --image ubuntu-22.04 \
  --ssh-key my-key \
  --user-data-from-file setup.sh
```

### Query with filters

**AWS:**
```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
  --output table
```

**Azure:**
```bash
az vm list \
  --query "[?powerState=='VM running'].{name:name, ip:publicIps}" \
  --output table
```

**GCP:**
```bash
gcloud compute instances list \
  --filter="status=RUNNING" \
  --format="table(name,networkInterfaces[0].accessConfigs[0].natIP)"
```

**Hetzner:**
```bash
hcloud server list -o json | jq -r '.[] | select(.status=="running") | .name + ": " + .public_net.ipv4.ip'
```

## Tips

### Use profiles/projects

- **AWS**: `aws --profile production`
- **Azure**: `az account set --subscription ID`
- **GCP**: `gcloud config configurations activate prod`
- **Hetzner**: `hcloud context use production`
- **OCI**: `oci --profile PRODUCTION`

### Enable command completion

```bash
# AWS
complete -C aws_completer aws

# Azure
az completion > ~/.azure/completion.sh
echo 'source ~/.azure/completion.sh' >> ~/.bashrc

# GCP
gcloud completion bash > ~/.gcloud-completion
source ~/.gcloud-completion

# Hetzner
hcloud completion bash > ~/.hcloud-completion
source ~/.hcloud-completion
```

### Format output for scripting

```bash
# Extract specific fields with jq
aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'

# Use --query for native filtering
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'

# Table format for humans
gcloud compute instances list --format=table
```
