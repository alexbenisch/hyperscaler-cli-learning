# Hetzner Cloud CLI Learning

Learn to use the `hcloud` CLI to manage Hetzner Cloud infrastructure.

## 📋 Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Basic Commands](#basic-commands)
- [Servers](#servers)
- [Networking](#networking)
- [Storage](#storage)
- [Example Projects](#example-projects)

## Installation

### Linux/macOS

```bash
# Download latest release
wget -qO- https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz | tar xz
sudo mv hcloud /usr/local/bin/

# Or via package manager
# Arch Linux
yay -S hcloud

# Homebrew (macOS)
brew install hcloud

# Verify installation
hcloud version
```

### Configuration

```bash
# Create API token at https://console.hetzner.cloud/
# Project → Security → API Tokens → Generate API Token

# Add context with your token
hcloud context create homelab

# Set active context
hcloud context use homelab

# Test connection
hcloud server list
```

## Basic Commands

### General

```bash
# List all commands
hcloud --help

# Get help for specific command
hcloud server --help

# Set output format
hcloud server list -o json
hcloud server list -o columns=id,name,status,ipv4

# Version info
hcloud version
```

### Server Locations and Types

```bash
# List available locations
hcloud location list

# List available server types
hcloud server-type list

# List available images
hcloud image list

# List available datacenters
hcloud datacenter list
```

## Servers

### Create and Manage Servers

```bash
# Create a simple server
hcloud server create \
  --name my-server \
  --type cx11 \
  --image ubuntu-22.04 \
  --ssh-key my-key

# Create server in specific location
hcloud server create \
  --name web-server \
  --type cpx21 \
  --image ubuntu-22.04 \
  --location nbg1 \
  --ssh-key my-key

# Create server with cloud-init
hcloud server create \
  --name docker-host \
  --type cx21 \
  --image ubuntu-22.04 \
  --ssh-key my-key \
  --user-data-from-file cloud-init.yaml

# List servers
hcloud server list

# Get server details
hcloud server describe my-server

# Get server IP
hcloud server ip my-server
```

### Server Operations

```bash
# Power operations
hcloud server poweroff my-server
hcloud server poweron my-server
hcloud server reboot my-server
hcloud server reset my-server

# Rescue mode
hcloud server enable-rescue my-server
hcloud server reset my-server  # Boot into rescue
hcloud server disable-rescue my-server

# Resize server (must be powered off)
hcloud server poweroff my-server
hcloud server change-type my-server --server-type cx21
hcloud server poweron my-server

# Delete server
hcloud server delete my-server
```

### SSH Keys

```bash
# Add SSH key
hcloud ssh-key create \
  --name my-key \
  --public-key-from-file ~/.ssh/id_rsa.pub

# List SSH keys
hcloud ssh-key list

# Delete SSH key
hcloud ssh-key delete my-key
```

## Networking

### Networks and Subnets

```bash
# Create network
hcloud network create \
  --name my-network \
  --ip-range 10.0.0.0/16

# Add subnet
hcloud network add-subnet my-network \
  --type server \
  --network-zone eu-central \
  --ip-range 10.0.1.0/24

# Attach server to network
hcloud server attach-to-network my-server \
  --network my-network \
  --ip 10.0.1.10

# List networks
hcloud network list

# Describe network
hcloud network describe my-network

# Detach from network
hcloud server detach-from-network my-server \
  --network my-network

# Delete network
hcloud network delete my-network
```

### Firewalls

```bash
# Create firewall
hcloud firewall create --name web-firewall

# Add rules (allow SSH and HTTP)
hcloud firewall add-rule web-firewall \
  --direction in \
  --protocol tcp \
  --port 22 \
  --source-ips 0.0.0.0/0 \
  --source-ips ::/0

hcloud firewall add-rule web-firewall \
  --direction in \
  --protocol tcp \
  --port 80 \
  --source-ips 0.0.0.0/0 \
  --source-ips ::/0

hcloud firewall add-rule web-firewall \
  --direction in \
  --protocol tcp \
  --port 443 \
  --source-ips 0.0.0.0/0 \
  --source-ips ::/0

# Apply firewall to server
hcloud firewall apply-to-resource web-firewall \
  --type server \
  --server my-server

# List firewalls
hcloud firewall list

# Remove firewall from server
hcloud firewall remove-from-resource web-firewall \
  --type server \
  --server my-server

# Delete firewall
hcloud firewall delete web-firewall
```

### Load Balancers

```bash
# Create load balancer
hcloud load-balancer create \
  --name my-lb \
  --type lb11 \
  --location nbg1

# Add service (HTTP)
hcloud load-balancer add-service my-lb \
  --protocol http \
  --listen-port 80 \
  --destination-port 80

# Add target (server)
hcloud load-balancer add-target my-lb \
  --server my-server

# List load balancers
hcloud load-balancer list

# Delete load balancer
hcloud load-balancer delete my-lb
```

## Storage

### Volumes

```bash
# Create volume
hcloud volume create \
  --name my-volume \
  --size 10 \
  --location nbg1

# Attach volume to server
hcloud volume attach my-volume my-server

# List volumes
hcloud volume list

# Describe volume
hcloud volume describe my-volume

# Resize volume
hcloud volume resize my-volume --size 20

# Detach volume
hcloud volume detach my-volume

# Delete volume
hcloud volume delete my-volume
```

## Example Projects

### Example 1: Simple Web Server

```bash
#!/bin/bash
# deploy-web-server.sh

# Create SSH key if not exists
if ! hcloud ssh-key list | grep -q "web-key"; then
  hcloud ssh-key create --name web-key --public-key-from-file ~/.ssh/id_rsa.pub
fi

# Create firewall
hcloud firewall create --name web-fw

# Add firewall rules
hcloud firewall add-rule web-fw --direction in --protocol tcp --port 22 --source-ips 0.0.0.0/0
hcloud firewall add-rule web-fw --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0
hcloud firewall add-rule web-fw --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0

# Create server with cloud-init
hcloud server create \
  --name web-server \
  --type cx11 \
  --image ubuntu-22.04 \
  --location nbg1 \
  --ssh-key web-key \
  --user-data "#cloud-config
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx"

# Apply firewall
sleep 5
hcloud firewall apply-to-resource web-fw --type server --server web-server

# Get server IP
IP=$(hcloud server ip web-server)
echo "Web server deployed at: http://$IP"
```

### Example 2: Private Network Setup

```bash
#!/bin/bash
# setup-private-network.sh

# Create network
hcloud network create --name private-net --ip-range 10.0.0.0/16

# Add subnet
hcloud network add-subnet private-net \
  --type server \
  --network-zone eu-central \
  --ip-range 10.0.1.0/24

# Create multiple servers
for i in {1..3}; do
  hcloud server create \
    --name app-server-$i \
    --type cx11 \
    --image ubuntu-22.04 \
    --ssh-key web-key

  # Attach to network
  hcloud server attach-to-network app-server-$i \
    --network private-net \
    --ip 10.0.1.$((10+i))
done

echo "Private network setup complete"
hcloud network describe private-net
```

## Tips and Best Practices

### Cost Optimization

```bash
# Use smallest server type for testing
hcloud server create --type cx11  # €3.29/month

# Delete servers when not needed
hcloud server delete my-server

# Use volumes for persistent data
# Volumes can be detached and reattached to different servers
```

### Automation

```bash
# Use JSON output for scripting
SERVER_ID=$(hcloud server create --name test --type cx11 --image ubuntu-22.04 -o json | jq -r '.id')

# Get server IP programmatically
IP=$(hcloud server describe my-server -o json | jq -r '.public_net.ipv4.ip')

# List all server IPs
hcloud server list -o json | jq -r '.[] | .name + ": " + .public_net.ipv4.ip'
```

### Security

```bash
# Always use SSH keys, never passwords
hcloud server create --ssh-key my-key  # Good
# Don't rely on root password

# Use firewalls
hcloud firewall create --name restrictive-fw
hcloud firewall add-rule restrictive-fw \
  --direction in \
  --protocol tcp \
  --port 22 \
  --source-ips YOUR_IP/32  # Restrict SSH to your IP

# Enable private networking for internal communication
# Servers can communicate via private IPs without exposing to internet
```

## Common Tasks

### SSH into Server

```bash
# Get server IP
IP=$(hcloud server ip my-server)

# SSH
ssh root@$IP

# Or use describe
ssh root@$(hcloud server describe my-server -o json | jq -r '.public_net.ipv4.ip')
```

### Backup and Snapshots

```bash
# Enable backups (costs extra)
hcloud server enable-backup my-server

# Create image from server
hcloud server create-image my-server --description "My custom image"

# List images
hcloud image list --type snapshot

# Create server from snapshot
hcloud server create \
  --name restored-server \
  --type cx11 \
  --image IMAGE_ID
```

## Resources

- [Hetzner Cloud Documentation](https://docs.hetzner.cloud/)
- [hcloud CLI GitHub](https://github.com/hetznercloud/cli)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Community Tutorials](https://community.hetzner.com/tutorials)

## Pricing

- **CX11**: €3.29/month (1 vCPU, 2GB RAM, 20GB SSD)
- **CPX11**: €3.85/month (2 vCPU, 2GB RAM, 40GB SSD)
- **CX21**: €5.39/month (2 vCPU, 4GB RAM, 40GB SSD)
- **Volumes**: €0.0476/GB/month
- **Load Balancers**: From €5.39/month

Check latest pricing at: https://www.hetzner.com/cloud
