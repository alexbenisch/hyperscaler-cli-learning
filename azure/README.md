# Azure CLI Learning

Learn to use the `az` CLI to manage Microsoft Azure infrastructure.

## 📋 Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Basic Commands](#basic-commands)
- [Compute (Virtual Machines)](#compute-virtual-machines)
- [Storage](#storage)
- [Networking](#networking)
- [Kubernetes (AKS)](#kubernetes-aks)
- [Example Projects](#example-projects)

## Installation

### Linux

```bash
# Install via script
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Or using apt (Ubuntu/Debian)
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt update && sudo apt install azure-cli

# Verify
az version
```

### macOS

```bash
# Using Homebrew
brew update && brew install azure-cli

# Verify
az version
```

## Configuration

```bash
# Login interactively
az login

# Login with service principal (for automation)
az login --service-principal \
  --username APP_ID \
  --password PASSWORD \
  --tenant TENANT_ID

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "My Subscription"

# Show current subscription
az account show

# Set default location
az configure --defaults location=eastus

# Set default resource group
az configure --defaults group=myResourceGroup

# Show configuration
az configure --list-defaults
```

## Basic Commands

### General

```bash
# Get help
az help
az vm help
az vm create --help

# List all resource groups
az group list --output table

# Create resource group
az group create --name myResourceGroup --location eastus

# Delete resource group (deletes all resources in it)
az group delete --name myResourceGroup --yes --no-wait

# Set output format
az vm list --output json
az vm list --output table
az vm list --output tsv

# Use JMESPath queries
az vm list --query "[].{name:name, location:location, powerState:powerState}" --output table

# List available locations
az account list-locations --output table

# List available VM sizes
az vm list-sizes --location eastus --output table
```

## Compute (Virtual Machines)

### List Available Resources

```bash
# List VM images (Ubuntu)
az vm image list \
  --publisher Canonical \
  --offer 0001-com-ubuntu-server-jammy \
  --all \
  --output table | head -20

# Or use aliases
az vm image list --output table  # Shows popular images

# List VM sizes
az vm list-sizes --location eastus --output table | grep Standard_B

# List availability zones
az vm list-skus --location eastus --zone --output table
```

### Create and Manage VMs

```bash
# Create resource group first
az group create --name myResourceGroup --location eastus

# Create VM (simple)
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys

# Create VM with specific SSH key
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

# Create VM with public IP and open ports
az vm create \
  --resource-group myResourceGroup \
  --name webVM \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --nsg-rule SSH

# Open port 80
az vm open-port \
  --resource-group myResourceGroup \
  --name webVM \
  --port 80 \
  --priority 1001

# Create VM with custom data (cloud-init)
az vm create \
  --resource-group myResourceGroup \
  --name webVM \
  --image Ubuntu2204 \
  --custom-data cloud-init.yaml \
  --admin-username azureuser \
  --generate-ssh-keys

# List VMs
az vm list --output table

# List VMs in resource group
az vm list --resource-group myResourceGroup --output table

# Get VM details
az vm show --resource-group myResourceGroup --name myVM

# Get VM public IP
az vm list-ip-addresses \
  --resource-group myResourceGroup \
  --name myVM \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
  --output tsv
```

### VM Operations

```bash
# Start VM
az vm start --resource-group myResourceGroup --name myVM

# Stop VM (deallocate - stops billing)
az vm deallocate --resource-group myResourceGroup --name myVM

# Stop VM (but keep billing)
az vm stop --resource-group myResourceGroup --name myVM

# Restart VM
az vm restart --resource-group myResourceGroup --name myVM

# Resize VM
az vm resize \
  --resource-group myResourceGroup \
  --name myVM \
  --size Standard_B2s

# Delete VM
az vm delete --resource-group myResourceGroup --name myVM --yes

# Get VM status
az vm get-instance-view \
  --resource-group myResourceGroup \
  --name myVM \
  --query instanceView.statuses[1].displayStatus \
  --output tsv

# Run command on VM
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "sudo apt update && sudo apt install -y nginx"

# SSH into VM
az ssh vm --resource-group myResourceGroup --name myVM
```

## Storage

### Blob Storage

```bash
# Create storage account
az storage account create \
  --name mystorageaccount123 \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS

# Get connection string
az storage account show-connection-string \
  --name mystorageaccount123 \
  --resource-group myResourceGroup \
  --output tsv

# Set default storage account
export AZURE_STORAGE_ACCOUNT=mystorageaccount123
export AZURE_STORAGE_KEY=$(az storage account keys list \
  --resource-group myResourceGroup \
  --account-name mystorageaccount123 \
  --query '[0].value' \
  --output tsv)

# Create container
az storage container create --name mycontainer

# Upload file
az storage blob upload \
  --container-name mycontainer \
  --name myfile.txt \
  --file ./local-file.txt

# Upload directory
az storage blob upload-batch \
  --destination mycontainer \
  --source ./local-dir

# List blobs
az storage blob list --container-name mycontainer --output table

# Download blob
az storage blob download \
  --container-name mycontainer \
  --name myfile.txt \
  --file ./downloaded-file.txt

# Download all blobs
az storage blob download-batch \
  --destination ./local-dir \
  --source mycontainer

# Delete blob
az storage blob delete --container-name mycontainer --name myfile.txt

# Delete container
az storage container delete --name mycontainer

# Generate SAS token (for temporary access)
az storage blob generate-sas \
  --container-name mycontainer \
  --name myfile.txt \
  --permissions r \
  --expiry 2024-12-31 \
  --https-only \
  --output tsv
```

### Managed Disks

```bash
# Create disk
az disk create \
  --resource-group myResourceGroup \
  --name myDisk \
  --size-gb 10 \
  --sku Standard_LRS

# List disks
az disk list --output table

# Attach disk to VM
az vm disk attach \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name myDisk

# Detach disk
az vm disk detach \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name myDisk

# Create snapshot
az snapshot create \
  --resource-group myResourceGroup \
  --name mySnapshot \
  --source myDisk

# List snapshots
az snapshot list --output table

# Delete disk
az disk delete --resource-group myResourceGroup --name myDisk --yes
```

## Networking

### Virtual Networks

```bash
# Create virtual network
az network vnet create \
  --resource-group myResourceGroup \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefix 10.0.1.0/24

# Create additional subnet
az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name mySubnet2 \
  --address-prefix 10.0.2.0/24

# List virtual networks
az network vnet list --output table

# List subnets
az network vnet subnet list \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --output table

# Delete virtual network
az network vnet delete \
  --resource-group myResourceGroup \
  --name myVNet
```

### Network Security Groups

```bash
# Create NSG
az network nsg create \
  --resource-group myResourceGroup \
  --name myNSG

# Add rule to allow SSH
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp

# Add rule to allow HTTP
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowHTTP \
  --priority 1001 \
  --destination-port-ranges 80 \
  --access Allow \
  --protocol Tcp

# List NSG rules
az network nsg rule list \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --output table

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name mySubnet \
  --network-security-group myNSG

# Delete NSG
az network nsg delete --resource-group myResourceGroup --name myNSG
```

### Load Balancers

```bash
# Create public IP
az network public-ip create \
  --resource-group myResourceGroup \
  --name myPublicIP \
  --sku Standard

# Create load balancer
az network lb create \
  --resource-group myResourceGroup \
  --name myLoadBalancer \
  --sku Standard \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool

# Add health probe
az network lb probe create \
  --resource-group myResourceGroup \
  --lb-name myLoadBalancer \
  --name myHealthProbe \
  --protocol tcp \
  --port 80

# Add load balancing rule
az network lb rule create \
  --resource-group myResourceGroup \
  --lb-name myLoadBalancer \
  --name myHTTPRule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe

# List load balancers
az network lb list --output table
```

## Kubernetes (AKS)

```bash
# Create AKS cluster
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-managed-identity

# Get credentials (updates ~/.kube/config)
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster

# List clusters
az aks list --output table

# Show cluster details
az aks show \
  --resource-group myResourceGroup \
  --name myAKSCluster

# Scale cluster
az aks scale \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3

# Upgrade cluster
az aks upgrade \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --kubernetes-version 1.28.0

# Stop cluster (to save costs)
az aks stop --resource-group myResourceGroup --name myAKSCluster

# Start cluster
az aks start --resource-group myResourceGroup --name myAKSCluster

# Delete cluster
az aks delete --resource-group myResourceGroup --name myAKSCluster --yes
```

## Example Projects

### Example 1: Web Server with Load Balancer

```bash
#!/bin/bash
# deploy-web-with-lb.sh

RG="web-rg"
LOCATION="eastus"
VNET="webVNet"
SUBNET="webSubnet"
NSG="webNSG"
LB="webLB"

# Create resource group
az group create --name $RG --location $LOCATION

# Create VNet
az network vnet create \
  --resource-group $RG \
  --name $VNET \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET \
  --subnet-prefix 10.0.1.0/24

# Create NSG
az network nsg create --resource-group $RG --name $NSG
az network nsg rule create --resource-group $RG --nsg-name $NSG \
  --name AllowHTTP --priority 1000 --destination-port-ranges 80 --access Allow --protocol Tcp

# Create VMs
for i in {1..2}; do
  az vm create \
    --resource-group $RG \
    --name webVM$i \
    --image Ubuntu2204 \
    --size Standard_B1s \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --nsg $NSG \
    --admin-username azureuser \
    --generate-ssh-keys \
    --custom-data "#cloud-config
packages:
  - nginx
runcmd:
  - echo 'Hello from VM $i' > /var/www/html/index.html"
done

echo "Web servers deployed"
```

### Example 2: Backup Automation

```bash
#!/bin/bash
# backup-vms.sh

RG="myResourceGroup"

# Get all VMs with tag Backup=true
VMS=$(az vm list \
  --resource-group $RG \
  --query "[?tags.Backup=='true'].name" \
  --output tsv)

for VM in $VMS; do
  echo "Creating snapshot for $VM"

  # Get OS disk name
  DISK=$(az vm show \
    --resource-group $RG \
    --name $VM \
    --query "storageProfile.osDisk.name" \
    --output tsv)

  # Create snapshot
  az snapshot create \
    --resource-group $RG \
    --name "${VM}-snapshot-$(date +%Y%m%d)" \
    --source $DISK \
    --tags AutoBackup=true
done

# Delete old snapshots (older than 7 days)
CUTOFF=$(date -d '7 days ago' +%Y-%m-%d)
az snapshot list \
  --resource-group $RG \
  --query "[?tags.AutoBackup=='true' && timeCreated<='$CUTOFF'].name" \
  --output tsv | while read SNAPSHOT; do
  echo "Deleting old snapshot: $SNAPSHOT"
  az snapshot delete --resource-group $RG --name $SNAPSHOT --yes
done
```

### Example 3: Cost Reporting

```bash
#!/bin/bash
# cost-report.sh

# Get current month costs
az consumption usage list \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d) \
  --query "[].{Service:product, Cost:pretaxCost}" \
  --output table

# Get costs by resource group
az consumption usage list \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d) \
  --query "[].{ResourceGroup:resourceGroup, Cost:pretaxCost}" \
  --output table | sort -k2 -n -r
```

## Tips and Best Practices

### Cost Optimization

```bash
# Stop VMs when not in use (deallocates and stops billing)
az vm deallocate --resource-group myResourceGroup --name myVM

# Use B-series burstable VMs for development
az vm create --size Standard_B1s  # Starting at $7.59/month

# Delete resources when done
az group delete --name myResourceGroup --yes --no-wait

# List all resources with costs
az resource list --output table
```

### Security

```bash
# Use managed identities instead of passwords
az vm identity assign --resource-group myResourceGroup --name myVM

# Enable disk encryption
az vm encryption enable \
  --resource-group myResourceGroup \
  --name myVM \
  --disk-encryption-keyvault myKeyVault

# Use Azure Key Vault for secrets
az keyvault create --resource-group myResourceGroup --name myKeyVault
az keyvault secret set --vault-name myKeyVault --name MySecret --value "secretvalue"

# Restrict network access
az vm update --resource-group myResourceGroup --name myVM --set networkProfile.networkInterfaces[0].primary=true
```

### Automation

```bash
# Use tags for organization
az vm create --tags Environment=Dev Project=WebApp

# Query resources by tags
az resource list --tag Environment=Dev --output table

# Export resource group as template
az group export --name myResourceGroup > template.json

# Deploy from template
az deployment group create \
  --resource-group myResourceGroup \
  --template-file template.json
```

## Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/reference-index)
- [Azure Free Account](https://azure.microsoft.com/free/)
- [Azure CLI on GitHub](https://github.com/Azure/azure-cli)

## Pricing

**Virtual Machines (East US):**
- Standard_B1s: $7.59/month (1 vCPU, 1GB RAM)
- Standard_B2s: $30.37/month (2 vCPU, 4GB RAM)
- Free tier: 750 hours/month B1s for 12 months

**Storage:**
- Blob Storage (LRS): $0.0184/GB/month
- Managed Disks (Standard HDD): $0.0416/GB/month

**AKS:**
- Free cluster management
- Pay only for VMs, storage, networking

Check latest pricing at: https://azure.microsoft.com/pricing/
