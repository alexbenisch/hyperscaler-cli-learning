# OKE Cluster Lifecycle Management

Complete lifecycle for creating, using, and destroying an OKE cluster for cost-effective learning.

## Prerequisites

- OCI CLI installed and configured (`~/.oci/config`)
- `kubectl` installed
- Tenancy with OKE enabled in target region

### Key OCIDs (eu-frankfurt-1, tenancy alexbenisch)
```
COMPARTMENT_ID=ocid1.tenancy.oc1..aaaaaaaa4l2e2645ogyfah3r46eqs2svglagwnywdrxvurrvsqsx6otnc2ga
```

---

## 1. Gather Prerequisites

```bash
# List compartments (root tenancy is used if empty)
oci iam compartment list --all

# List existing VCNs
oci network vcn list --compartment-id $COMPARTMENT_ID

# Available K8s versions
oci ce cluster-options get --cluster-option-id all \
  | python3 -c "import sys,json; [print(v) for v in json.load(sys.stdin)['data']['kubernetes-versions']]"

# Available ADs
oci iam availability-domain list --compartment-id $COMPARTMENT_ID
```

---

## 2. Create VCN and Networking

```bash
# Create VCN
oci network vcn create \
  --compartment-id $COMPARTMENT_ID \
  --display-name "oke-vcn" \
  --cidr-block "10.0.0.0/16" \
  --dns-label "okevcn" \
  --wait-for-state AVAILABLE

VCN_ID=<vcn-id-from-output>

# Create Internet Gateway
oci network internet-gateway create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name "oke-igw" \
  --is-enabled true \
  --wait-for-state AVAILABLE

IGW_ID=<igw-id-from-output>

# Get default route table and security list IDs from vcn create output
DEFAULT_RT=<default-route-table-id>
DEFAULT_SL=<default-security-list-id>
DEFAULT_DHCP=<default-dhcp-options-id>

# Add default route to IGW
oci network route-table update \
  --rt-id $DEFAULT_RT \
  --route-rules "[{\"cidrBlock\":\"0.0.0.0/0\",\"networkEntityId\":\"$IGW_ID\"}]" \
  --force --wait-for-state AVAILABLE

# Open security list (learning env — allow all)
oci network security-list update \
  --security-list-id $DEFAULT_SL \
  --ingress-security-rules '[{"protocol":"all","source":"0.0.0.0/0","isStateless":false}]' \
  --egress-security-rules '[{"protocol":"all","destination":"0.0.0.0/0","isStateless":false}]' \
  --force --wait-for-state AVAILABLE

# Public subnet (for LoadBalancer)
oci network subnet create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name "oke-public-subnet" \
  --cidr-block "10.0.0.0/24" \
  --dns-label "okepublic" \
  --route-table-id $DEFAULT_RT \
  --security-list-ids "[\"$DEFAULT_SL\"]" \
  --dhcp-options-id $DEFAULT_DHCP \
  --prohibit-public-ip-on-vnic false \
  --wait-for-state AVAILABLE

PUBLIC_SUBNET=<subnet-id-from-output>

# Node subnet (for worker nodes)
oci network subnet create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name "oke-node-subnet" \
  --cidr-block "10.0.1.0/24" \
  --dns-label "okenodes" \
  --route-table-id $DEFAULT_RT \
  --security-list-ids "[\"$DEFAULT_SL\"]" \
  --dhcp-options-id $DEFAULT_DHCP \
  --prohibit-public-ip-on-vnic false \
  --wait-for-state AVAILABLE

NODE_SUBNET=<subnet-id-from-output>
```

**Time**: ~2 minutes

---

## 3. Create OKE Cluster

```bash
oci ce cluster create \
  --compartment-id $COMPARTMENT_ID \
  --name "oke-learning" \
  --vcn-id $VCN_ID \
  --kubernetes-version "v1.33.1" \
  --endpoint-subnet-id $PUBLIC_SUBNET \
  --wait-for-state SUCCEEDED

CLUSTER_ID=<cluster-id-from-resources[].identifier>
```

**Time**: ~7 minutes

> **Note**: Cluster starts with private+VCN hostname endpoints only.
> Enable public endpoint after creation (step 5).

---

## 4. Create Node Pool

```bash
# Find a compatible image for your shape
oci ce node-pool-options get --node-pool-option-id $CLUSTER_ID \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
for s in data.get('sources', []):
    name = s.get('source-name','')
    if 'aarch64' not in name and 'GPU' not in name and 'v1.33.1' in name.replace('OKE-1.33.1','v1.33.1'):
        print(name[:80], s['image-id'])
" | head -5

NODE_IMAGE=<image-id>

# Get availability domain
AD=$(oci iam availability-domain list --compartment-id $COMPARTMENT_ID \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['name'])")

# Create node pool (VM.Standard.E2.1 = cheapest available x86 in most tenancies)
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

NODEPOOL_ID=<nodepool-id-from-resources[].identifier>
```

**Time**: ~3 minutes

> **Shape/Image compatibility**: x86 shapes (`E2.x`) need non-`aarch64` images.
> ARM shapes (`A1.Flex`, `A2.Flex`) need `aarch64` images.

---

## 5. Enable Public Endpoint

```bash
oci ce cluster update-endpoint-config \
  --cluster-id $CLUSTER_ID \
  --is-public-ip-enabled true \
  --wait-for-state SUCCEEDED

# Verify public IP is assigned
oci ce cluster get --cluster-id $CLUSTER_ID \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['endpoints'])"
```

**Time**: ~2 minutes

---

## 6. Configure kubectl

```bash
oci ce cluster create-kubeconfig \
  --cluster-id $CLUSTER_ID \
  --file ~/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT

# Verify
kubectl cluster-info
kubectl get nodes
# Both nodes should show Ready
```

> **VCN hostname endpoint** (`*.okevcn.oraclevcn.com`) only resolves inside OCI.
> Always use `PUBLIC_ENDPOINT` for external access.

---

## 7. Deploy nginx Test Workload

```bash
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# OCI CCM requires subnet annotation to provision LB
kubectl annotate svc nginx \
  "service.beta.kubernetes.io/oci-load-balancer-subnet1=$PUBLIC_SUBNET"

# Wait for EXTERNAL-IP (~2 min)
kubectl get svc nginx --watch

LB_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$LB_IP
# Should return nginx welcome page
```

**Time**: ~2 minutes for LB provisioning

---

## 8. Teardown (Delete in Order)

```bash
# 1. Delete LB first (must do before cluster delete to avoid orphaned OCI LBs)
kubectl delete svc nginx
kubectl delete deployment nginx

# 2. Wait for LB to de-provision (~1-2 min), then delete node pool
oci ce node-pool delete \
  --node-pool-id $NODEPOOL_ID \
  --force \
  --wait-for-state SUCCEEDED

# 3. Delete cluster
oci ce cluster delete \
  --cluster-id $CLUSTER_ID \
  --force \
  --wait-for-state SUCCEEDED

# 4. Delete networking (subnets before VCN)
oci network subnet delete --subnet-id $NODE_SUBNET --force --wait-for-state TERMINATED
oci network subnet delete --subnet-id $PUBLIC_SUBNET --force --wait-for-state TERMINATED
oci network internet-gateway delete --ig-id $IGW_ID --force --wait-for-state TERMINATED
oci network vcn delete --vcn-id $VCN_ID --force --wait-for-state TERMINATED

# 5. Verify nothing remains
oci ce cluster list --compartment-id $COMPARTMENT_ID
oci network vcn list --compartment-id $COMPARTMENT_ID
```

**Time**: ~5-10 minutes total

> **Cost risk**: OCI LoadBalancers continue billing if orphaned (not deleted before cluster).
> Always delete the kubernetes Service before deleting the cluster.

---

## Lifecycle Timeline

### Demo Session — 2026-04-15

| Time (UTC) | Action | Duration |
|------------|--------|----------|
| 11:00 | Create VCN + networking | ~2 min |
| 11:02 | Create OKE cluster | ~7 min |
| 11:12 | Create node pool | ~3 min |
| 11:15 | Enable public endpoint | ~2 min |
| 11:18 | Configure kubectl | <1 min |
| 11:18 | Deploy nginx + LB | ~2 min |
| 11:20 | Verify curl | <1 min |
| TBD | Teardown | ~10 min |

**Total setup time**: ~17 minutes  
**Estimated cost for 1hr**: ~$0.08

---

## Cost Reference

| Resource | Rate |
|----------|------|
| VM.Standard.E2.1 node | ~$0.028/hr each |
| OKE control plane | Free |
| OCI Flexible LoadBalancer | ~$0.025/hr |
| VCN, subnets, IGW | Free |
| **Total (2 nodes + 1 LB)** | **~$0.08/hr** |

---

## Key OCI Differences vs AWS/GCP/Azure

| Concept | OCI | AWS | GCP |
|---------|-----|-----|-----|
| Network | VCN | VPC | VPC |
| Cluster fee | Free | $0.10/hr | Free |
| Node groups | Node Pools | Node Groups | Node Pools |
| LB auto-subnet | Manual annotation | Auto-detected | Auto-detected |
| kubectl auth | OCI token (v2.0.0) | aws-iam-authenticator | gke-gcloud-auth-plugin |
| Default endpoint | Private only | Public | Public |
