#!/usr/bin/env bash
# OKE (Oracle Kubernetes Engine) Command Cheat Sheet
# Region: eu-frankfurt-1 | Tenancy: alexbenisch
# Usage: source this file or copy individual commands

# ── Variables ────────────────────────────────────────────────────────────────
export COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaa4l2e2645ogyfah3r46eqs2svglagwnywdrxvurrvsqsx6otnc2ga"
export REGION="eu-frankfurt-1"
export SUPPRESS_LABEL_WARNING=True

# Fill in after creation:
# export CLUSTER_ID=""
# export NODEPOOL_ID=""
# export VCN_ID=""
# export PUBLIC_SUBNET=""
# export NODE_SUBNET=""
# export IGW_ID=""

# ── Prerequisites ─────────────────────────────────────────────────────────────

# List compartments
oci iam compartment list --all --compartment-id $COMPARTMENT_ID

# Available K8s versions
oci ce cluster-options get --cluster-option-id all \
  | python3 -c "import sys,json; [print(v) for v in json.load(sys.stdin)['data']['kubernetes-versions']]"

# Available ADs
oci iam availability-domain list --compartment-id $COMPARTMENT_ID

# ── Networking ────────────────────────────────────────────────────────────────

# Create VCN
oci network vcn create \
  --compartment-id $COMPARTMENT_ID \
  --display-name "oke-vcn" \
  --cidr-block "10.0.0.0/16" \
  --dns-label "okevcn" \
  --wait-for-state AVAILABLE

# Create Internet Gateway
oci network internet-gateway create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name "oke-igw" \
  --is-enabled true \
  --wait-for-state AVAILABLE

# Update default route table (add 0.0.0.0/0 -> IGW)
oci network route-table update \
  --rt-id $DEFAULT_RT \
  --route-rules "[{\"cidrBlock\":\"0.0.0.0/0\",\"networkEntityId\":\"$IGW_ID\"}]" \
  --force --wait-for-state AVAILABLE

# Open security list (learning env)
oci network security-list update \
  --security-list-id $DEFAULT_SL \
  --ingress-security-rules '[{"protocol":"all","source":"0.0.0.0/0","isStateless":false}]' \
  --egress-security-rules '[{"protocol":"all","destination":"0.0.0.0/0","isStateless":false}]' \
  --force --wait-for-state AVAILABLE

# Create public subnet (LoadBalancer)
oci network subnet create \
  --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
  --display-name "oke-public-subnet" --cidr-block "10.0.0.0/24" \
  --dns-label "okepublic" --route-table-id $DEFAULT_RT \
  --security-list-ids "[\"$DEFAULT_SL\"]" --dhcp-options-id $DEFAULT_DHCP \
  --prohibit-public-ip-on-vnic false --wait-for-state AVAILABLE

# Create node subnet (worker nodes)
oci network subnet create \
  --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
  --display-name "oke-node-subnet" --cidr-block "10.0.1.0/24" \
  --dns-label "okenodes" --route-table-id $DEFAULT_RT \
  --security-list-ids "[\"$DEFAULT_SL\"]" --dhcp-options-id $DEFAULT_DHCP \
  --prohibit-public-ip-on-vnic false --wait-for-state AVAILABLE

# List subnets
oci network subnet list --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID

# ── Cluster Lifecycle ─────────────────────────────────────────────────────────

# Create cluster (~7 min)
oci ce cluster create \
  --compartment-id $COMPARTMENT_ID \
  --name "oke-learning" \
  --vcn-id $VCN_ID \
  --kubernetes-version "v1.33.1" \
  --endpoint-subnet-id $PUBLIC_SUBNET \
  --wait-for-state SUCCEEDED

# List clusters
oci ce cluster list --compartment-id $COMPARTMENT_ID

# Get cluster details
oci ce cluster get --cluster-id $CLUSTER_ID

# Enable public endpoint (required for external kubectl access)
oci ce cluster update-endpoint-config \
  --cluster-id $CLUSTER_ID \
  --is-public-ip-enabled true \
  --wait-for-state SUCCEEDED

# Delete cluster
oci ce cluster delete --cluster-id $CLUSTER_ID --force --wait-for-state SUCCEEDED

# ── Node Pool ─────────────────────────────────────────────────────────────────

# Find compatible node images
oci ce node-pool-options get --node-pool-option-id $CLUSTER_ID \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
print('Shapes:', data.get('shapes', [])[:10])
for s in data.get('sources', []):
    n = s.get('source-name','')
    if 'aarch64' not in n and 'GPU' not in n and '1.33' in n:
        print(n[:80])
"

# Create node pool (~3 min)
oci ce node-pool create \
  --compartment-id $COMPARTMENT_ID \
  --cluster-id $CLUSTER_ID \
  --name "oke-nodepool" \
  --kubernetes-version "v1.33.1" \
  --node-shape "VM.Standard.E2.1" \
  --node-source-details "{\"imageId\":\"$NODE_IMAGE\",\"sourceType\":\"IMAGE\"}" \
  --size 2 \
  --placement-configs "[{\"availabilityDomain\":\"$AD\",\"subnetId\":\"$NODE_SUBNET\"}]" \
  --wait-for-state SUCCEEDED

# List node pools
oci ce node-pool list --compartment-id $COMPARTMENT_ID --cluster-id $CLUSTER_ID

# Delete node pool
oci ce node-pool delete --node-pool-id $NODEPOOL_ID --force --wait-for-state SUCCEEDED

# ── kubectl Access ────────────────────────────────────────────────────────────

# Generate kubeconfig (public endpoint)
oci ce cluster create-kubeconfig \
  --cluster-id $CLUSTER_ID \
  --file ~/.kube/config \
  --region $REGION \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT

# Verify access
kubectl cluster-info
kubectl get nodes
kubectl get pods -A -o wide

# ── nginx Test Workload ───────────────────────────────────────────────────────

# Deploy
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# REQUIRED: annotate with subnet OCID (OCI CCM doesn't auto-detect)
kubectl annotate svc nginx \
  "service.beta.kubernetes.io/oci-load-balancer-subnet1=$PUBLIC_SUBNET"

# Watch for LB IP (~2 min)
kubectl get svc nginx --watch

# Get LB IP and test
LB_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$LB_IP

# Clean up
kubectl delete svc nginx
kubectl delete deployment nginx

# ── Teardown (Order Matters!) ─────────────────────────────────────────────────

# 1. Remove LB first (avoids orphaned OCI LoadBalancers)
kubectl delete svc nginx 2>/dev/null; kubectl delete deployment nginx 2>/dev/null

# 2. Delete node pool
oci ce node-pool delete --node-pool-id $NODEPOOL_ID --force --wait-for-state SUCCEEDED

# 3. Delete cluster
oci ce cluster delete --cluster-id $CLUSTER_ID --force --wait-for-state SUCCEEDED

# 4. Delete networking
oci network subnet delete --subnet-id $NODE_SUBNET --force --wait-for-state TERMINATED
oci network subnet delete --subnet-id $PUBLIC_SUBNET --force --wait-for-state TERMINATED
oci network internet-gateway delete --ig-id $IGW_ID --force --wait-for-state TERMINATED
oci network vcn delete --vcn-id $VCN_ID --force --wait-for-state TERMINATED

# 5. Verify clean
oci ce cluster list --compartment-id $COMPARTMENT_ID
oci network vcn list --compartment-id $COMPARTMENT_ID

# ── Debugging ─────────────────────────────────────────────────────────────────

# Check service events (useful for LB issues)
kubectl describe svc nginx

# Check current context
kubectl config current-context
kubectl config view --minify | grep server

# Check work request status
oci ce work-request get --work-request-id $WORK_REQUEST_ID

# List all work requests
oci ce work-request list --compartment-id $COMPARTMENT_ID
