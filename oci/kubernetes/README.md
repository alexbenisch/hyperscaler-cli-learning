# OKE (Oracle Kubernetes Engine) Setup

This directory contains information about the OKE cluster setup for learning purposes.

## Current Cluster

**Cluster Name**: `oke-learning`
**Tenancy**: `alexbenisch`
**Region**: `eu-frankfurt-1` (Frankfurt)
**Kubernetes Version**: `v1.33.1`
**Control Plane IP**: `152.70.44.139`
**Node Count**: 2 nodes
**Node Shape**: `VM.Standard.E2.1` (1 OCPU, 8GB RAM)
**Node Image**: Oracle Linux 8.10

### Networking
- **VCN**: `oke-vcn` (`10.0.0.0/16`)
- **Public Subnet** (LB): `10.0.0.0/24`
- **Node Subnet**: `10.0.1.0/24`
- **Internet Gateway**: `oke-igw`

### OCI-Specific Concepts
- **Compartment**: Root tenancy is the compartment for this setup
- **VCN**: Oracle's Virtual Cloud Network (equivalent to AWS VPC / Azure VNet)
- **OKE Shapes**: VM types; `E2.1` is x86, `A1.Flex` is ARM — must match image arch
- **LB Subnet Annotation**: OCI CCM requires `service.beta.kubernetes.io/oci-load-balancer-subnet1` annotation to provision a LoadBalancer service

## Cluster Access

### Get Credentials
```bash
oci ce cluster create-kubeconfig \
  --cluster-id <cluster-id> \
  --file ~/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT
```

### Basic Commands
```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes -o wide

# List all pods
kubectl get pods -A -o wide

# Get cluster details
oci ce cluster get --cluster-id <cluster-id>
```

## Live Cluster State

### Pods (`kubectl get pods -A -o wide`)

```
NAMESPACE     NAME                                      READY   STATUS    RESTARTS       AGE   IP           NODE
default       nginx-54c98b4f84-bskjq                    1/1     Running   0              11m   10.244.1.3   10.0.1.163
kube-system   coredns-66795667d6-gptv9                  1/1     Running   0              18m   10.244.0.5   10.0.1.226
kube-system   coredns-66795667d6-l2frt                  1/1     Running   0              51m   10.244.0.2   10.0.1.226
kube-system   csi-oci-node-dzzzp                        1/1     Running   10 (22m ago)   46m   10.0.1.226   10.0.1.226
kube-system   csi-oci-node-vxnvl                        1/1     Running   10 (22m ago)   45m   10.0.1.163   10.0.1.163
kube-system   kube-dns-autoscaler-96c4fb5d5-64qlw       1/1     Running   0              51m   10.244.0.3   10.0.1.226
kube-system   kube-flannel-ds-br9f2                     1/1     Running   0              45m   10.0.1.163   10.0.1.163
kube-system   kube-flannel-ds-xg66g                     1/1     Running   1 (44m ago)    46m   10.0.1.226   10.0.1.226
kube-system   kube-proxy-s6vs7                          1/1     Running   0              46m   10.0.1.226   10.0.1.226
kube-system   kube-proxy-tb4h8                          1/1     Running   0              45m   10.0.1.163   10.0.1.163
kube-system   oke-dataplane-observability-agent-sp6g7   2/2     Running   0              19m   10.0.1.226   10.0.1.226
kube-system   oke-dataplane-observability-agent-z9qz2   2/2     Running   0              18m   10.0.1.163   10.0.1.163
kube-system   oke-node-problem-detector-5wjfn           1/1     Running   0              18m   10.244.1.2   10.0.1.163
kube-system   oke-node-problem-detector-bj5xd           1/1     Running   1 (19m ago)    19m   10.244.0.4   10.0.1.226
kube-system   proxymux-client-jjbwq                     1/1     Running   0              46m   10.0.1.226   10.0.1.226
kube-system   proxymux-client-mrlkc                     1/1     Running   0              45m   10.0.1.163   10.0.1.163
```

**OKE-specific system pods:**
- `csi-oci-node` — OCI block storage CSI driver (DaemonSet)
- `oke-dataplane-observability-agent` — OKE observability/metrics (DaemonSet, 2 containers)
- `oke-node-problem-detector` — detects node-level problems (DaemonSet)
- `proxymux-client` — OCI internal proxy for API server communication (DaemonSet)
- `kube-flannel` — CNI networking (FLANNEL_OVERLAY mode)

## Cluster Management

### List Clusters
```bash
oci ce cluster list --compartment-id <compartment-id>
```

### Delete Cluster (Cost Savings)
See [cluster-lifecycle.md](cluster-lifecycle.md) for full teardown sequence.

## Deploy Sample Application

### Deploy nginx with OCI LoadBalancer
```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Expose with LoadBalancer — must annotate with subnet OCID
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl annotate svc nginx \
  "service.beta.kubernetes.io/oci-load-balancer-subnet1=<public-subnet-ocid>"

# Wait for OCI LB to provision (~2 min)
kubectl get svc nginx --watch

# Test
LB_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$LB_IP

# Clean up (delete LB first to avoid orphans)
kubectl delete svc nginx
kubectl delete deployment nginx
```

## Cost Information

Estimated cost for this cluster while running:
- **2 x VM.Standard.E2.1 nodes**: ~$0.028/hour each = ~$0.056/hour total
- **OKE cluster fee**: Free (OKE control plane is free in OCI)
- **OCI LoadBalancer**: ~$0.025/hour (flexible LB, minimum 10 Mbps)

**Total**: ~$0.08/hour (~$58/month if left running)

**For learning**: Delete immediately after use. Total demo cost: ~$0.50.

## Troubleshooting

### LoadBalancer Stays Pending
OCI CCM requires a subnet annotation — add it:
```bash
kubectl annotate svc <svc-name> \
  "service.beta.kubernetes.io/oci-load-balancer-subnet1=<public-subnet-ocid>"
```

### kubectl Can't Connect
Check which endpoint your kubeconfig uses:
```bash
kubectl config view --minify | grep server
```
If it's the VCN hostname (`*.okevcn.oraclevcn.com`), regenerate with `PUBLIC_ENDPOINT`:
```bash
oci ce cluster create-kubeconfig ... --kube-endpoint PUBLIC_ENDPOINT
```

### Shape/Image Incompatibility
ARM shapes (`A1.Flex`, `A2.Flex`) require `aarch64` images.
x86 shapes (`E2.x`) require the non-`aarch64` Oracle Linux images.

## Additional Resources

- [OKE Documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm)
- [OCI CLI Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Cluster Lifecycle Management](cluster-lifecycle.md)

## Cluster History

### Demo Session — 2026-04-15
**Created**: 2026-04-15 ~11:00 UTC
**Deleted**: TBD
**Region**: eu-frankfurt-1

**Configuration**:
- Kubernetes: v1.33.1
- Nodes: 2 x VM.Standard.E2.1
- VCN: 10.0.0.0/16 with public + node subnets
- CNI: Flannel Overlay

**Key Learnings**:
- OKE cluster creation takes ~7 min, node pool ~3 min
- `VM.Standard.E4.Flex` not available in all tenancies — `E2.1` used instead
- OCI CCM needs `oci-load-balancer-subnet1` annotation (not auto-detected)
- Default cluster endpoint is private-only; must call `update-endpoint-config --is-public-ip-enabled true`
- `oci ce cluster create` uses `--endpoint-subnet-id`, NOT `--endpoint-config`

To recreate, see [cluster-lifecycle.md](cluster-lifecycle.md).
