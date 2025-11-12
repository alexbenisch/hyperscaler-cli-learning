Yes — just like AWS has **Boto3**, other hyperscalers also have robust, officially maintained **Python SDKs** (and often multi-language SDKs) for infrastructure and resource automation.

Here’s a clear comparison of the main libraries, their use cases, and some nuances:

---

## ☁️ Cloud SDK Overview for Automation

| Provider               | Library                                                                                                 | Language | Common Name / Package      | Notes                                                                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------- | -------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AWS**                | [Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)                             | Python   | `boto3`                    | Full AWS API coverage. Used for provisioning, IAM, Lambda, S3, EC2, etc.                                                                                                  |
| **Google Cloud**       | [Google Cloud Client Libraries](https://cloud.google.com/apis/docs/cloud-client-libraries)              | Python   | `google-cloud-*` (modular) | Each service has its own package (e.g. `google-cloud-storage`, `google-cloud-compute`). There’s also a REST-level client (`google-api-python-client`) for generic access. |
| **Oracle Cloud (OCI)** | [Oracle Cloud Infrastructure SDK](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/pythonsdk.htm) | Python   | `oci`                      | One unified library for all OCI services. Good CLI parity, supports auth via config or instance principals.                                                               |
| **Microsoft Azure**    | [Azure SDK for Python](https://learn.microsoft.com/en-us/azure/developer/python/sdk/azure-sdk-overview) | Python   | `azure-*`                  | Modular SDK, e.g. `azure-mgmt-compute`, `azure-storage-blob`, `azure-identity`. Built around the Azure REST APIs.                                                         |
| **Hetzner Cloud**      | [Hetzner Cloud Python Client](https://github.com/hetznercloud/hcloud-python)                            | Python   | `hcloud`                   | Simple SDK covering most Hetzner Cloud API endpoints (servers, volumes, networks). Great for lightweight automation.                                                      |

---

## 🧰 Comparison by Developer Experience

| Feature             | AWS (boto3)              | GCP                                         | OCI                 | Azure                      | Hetzner       |
| ------------------- | ------------------------ | ------------------------------------------- | ------------------- | -------------------------- | ------------- |
| **Auth setup**      | via `~/.aws/credentials` | via `gcloud auth application-default login` | via `~/.oci/config` | via `az login` or env vars | via API token |
| **Unified SDK**     | ✅ single package         | ❌ modular packages                          | ✅ unified           | ❌ modular                  | ✅ unified     |
| **CLI integration** | AWS CLI                  | gcloud CLI                                  | OCI CLI             | Azure CLI                  | hcloud CLI    |
| **Async support**   | limited                  | partial                                     | partial             | good (async variants)      | limited       |
| **Ease of use**     | ✅✅✅                      | ✅✅                                          | ✅✅                  | ✅✅                         | ✅✅✅           |
| **Breadth of APIs** | 🔥 full coverage         | broad                                       | broad               | broad                      | focused       |

---

## 🧩 Example Snippets

### Compute Instances

**AWS – EC2 instance list**

```python
import boto3
ec2 = boto3.client('ec2')
for instance in ec2.describe_instances()['Reservations']:
    print(instance['Instances'][0]['InstanceId'])
```

**GCP – List compute instances**

```python
from google.cloud import compute_v1
client = compute_v1.InstancesClient()
for instance in client.list(project="my-project", zone="europe-west1-b"):
    print(instance.name)
```

**OCI – List compute instances**

```python
import oci
config = oci.config.from_file()
compute = oci.core.ComputeClient(config)
for instance in compute.list_instances(config["compartment_id"]).data:
    print(instance.display_name)
```

**Azure – List VMs**

```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient

credential = DefaultAzureCredential()
client = ComputeManagementClient(credential, "YOUR_SUBSCRIPTION_ID")

for vm in client.virtual_machines.list_all():
    print(vm.name)
```

**Hetzner – List servers**

```python
from hcloud import Client
client = Client(token="YOUR_API_TOKEN")
for server in client.servers.get_all():
    print(server.name)
```

---

## 🚢 Kubernetes Cluster Management

### AWS EKS – List and manage clusters

```python
import boto3

# Initialize EKS client
eks = boto3.client('eks', region_name='us-east-1')

# List all EKS clusters
clusters = eks.list_clusters()
print("EKS Clusters:", clusters['clusters'])

# Get cluster details
for cluster_name in clusters['clusters']:
    cluster = eks.describe_cluster(name=cluster_name)
    print(f"\nCluster: {cluster['cluster']['name']}")
    print(f"Status: {cluster['cluster']['status']}")
    print(f"Version: {cluster['cluster']['version']}")
    print(f"Endpoint: {cluster['cluster']['endpoint']}")

# List node groups for a cluster
nodegroups = eks.list_nodegroups(clusterName='learning-eks-cluster')
print("\nNode Groups:", nodegroups['nodegroups'])

# Get node group details
for ng_name in nodegroups['nodegroups']:
    ng = eks.describe_nodegroup(
        clusterName='learning-eks-cluster',
        nodegroupName=ng_name
    )
    print(f"\nNode Group: {ng['nodegroup']['nodegroupName']}")
    print(f"Status: {ng['nodegroup']['status']}")
    print(f"Desired Size: {ng['nodegroup']['scalingConfig']['desiredSize']}")
    print(f"Instance Types: {ng['nodegroup']['instanceTypes']}")
```

### GCP GKE – List and manage clusters

```python
from google.cloud import container_v1

# Initialize client
client = container_v1.ClusterManagerClient()
project_id = "my-project"
location = "europe-west3"  # or specific zone

# List clusters
parent = f"projects/{project_id}/locations/{location}"
clusters = client.list_clusters(parent=parent)

for cluster in clusters.clusters:
    print(f"\nCluster: {cluster.name}")
    print(f"Status: {cluster.status}")
    print(f"Version: {cluster.current_master_version}")
    print(f"Node Count: {cluster.current_node_count}")
    print(f"Endpoint: {cluster.endpoint}")
```

### Azure AKS – List and manage clusters

```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerservice import ContainerServiceClient

# Initialize
credential = DefaultAzureCredential()
subscription_id = "YOUR_SUBSCRIPTION_ID"
client = ContainerServiceClient(credential, subscription_id)

# List all AKS clusters
for cluster in client.managed_clusters.list():
    print(f"\nCluster: {cluster.name}")
    print(f"Location: {cluster.location}")
    print(f"Status: {cluster.provisioning_state}")
    print(f"K8s Version: {cluster.kubernetes_version}")
    print(f"FQDN: {cluster.fqdn}")

# Get specific cluster
resource_group = "learning-k8s-rg"
cluster_name = "learning-cluster"
cluster = client.managed_clusters.get(resource_group, cluster_name)
print(f"\nAgent Pools: {len(cluster.agent_pool_profiles)}")
for pool in cluster.agent_pool_profiles:
    print(f"  - {pool.name}: {pool.count} nodes of {pool.vm_size}")
```

### AWS EKS – Create and delete cluster (using boto3)

```python
import boto3
import time

eks = boto3.client('eks', region_name='us-east-1')
ec2 = boto3.client('ec2', region_name='us-east-1')

# Note: Creating a cluster via boto3 requires extensive VPC/IAM setup
# For learning purposes, eksctl (Python wrapper) or eksctl CLI is recommended

# Create cluster (simplified - requires pre-existing VPC and IAM roles)
def create_cluster(cluster_name, role_arn, subnet_ids, security_group_ids):
    response = eks.create_cluster(
        name=cluster_name,
        version='1.32',
        roleArn=role_arn,
        resourcesVpcConfig={
            'subnetIds': subnet_ids,
            'securityGroupIds': security_group_ids
        }
    )
    return response['cluster']

# Delete cluster
def delete_cluster(cluster_name):
    # First, delete all node groups
    nodegroups = eks.list_nodegroups(clusterName=cluster_name)
    for ng in nodegroups['nodegroups']:
        eks.delete_nodegroup(
            clusterName=cluster_name,
            nodegroupName=ng
        )
        print(f"Deleting node group: {ng}")

    # Wait for node groups to delete
    time.sleep(300)  # 5 minutes

    # Then delete the cluster
    response = eks.delete_cluster(name=cluster_name)
    print(f"Cluster {cluster_name} deletion initiated")
    return response

# Example: Delete cluster
# delete_cluster('learning-eks-cluster')
```

### Practical EKS Automation with boto3

```python
import boto3
from datetime import datetime

class EKSManager:
    def __init__(self, region='us-east-1'):
        self.eks = boto3.client('eks', region_name=region)
        self.region = region

    def list_clusters(self):
        """List all EKS clusters in the region"""
        response = self.eks.list_clusters()
        return response['clusters']

    def get_cluster_info(self, cluster_name):
        """Get detailed information about a cluster"""
        cluster = self.eks.describe_cluster(name=cluster_name)['cluster']
        return {
            'name': cluster['name'],
            'status': cluster['status'],
            'version': cluster['version'],
            'endpoint': cluster['endpoint'],
            'created': cluster['createdAt'],
            'vpc_id': cluster['resourcesVpcConfig']['vpcId'],
            'subnet_ids': cluster['resourcesVpcConfig']['subnetIds']
        }

    def get_cluster_cost_estimate(self, cluster_name):
        """Estimate monthly cost for a cluster"""
        # Control plane cost (fixed)
        control_plane_cost = 0.10 * 24 * 30  # $73/month

        # Get node groups
        nodegroups = self.eks.list_nodegroups(clusterName=cluster_name)

        total_node_cost = 0
        for ng_name in nodegroups['nodegroups']:
            ng = self.eks.describe_nodegroup(
                clusterName=cluster_name,
                nodegroupName=ng_name
            )['nodegroup']

            # Simplified cost calculation (would need EC2 pricing API for accuracy)
            instance_type = ng['instanceTypes'][0] if ng['instanceTypes'] else 't3.medium'
            desired_size = ng['scalingConfig']['desiredSize']

            # Rough estimates (actual prices vary by region)
            instance_costs = {
                't3.micro': 0.0104,
                't3.small': 0.0208,
                't3.medium': 0.0416,
                't3.large': 0.0832
            }

            hourly_cost = instance_costs.get(instance_type, 0.0416)
            monthly_node_cost = hourly_cost * 24 * 30 * desired_size
            total_node_cost += monthly_node_cost

        return {
            'control_plane': round(control_plane_cost, 2),
            'nodes': round(total_node_cost, 2),
            'total': round(control_plane_cost + total_node_cost, 2)
        }

    def scale_nodegroup(self, cluster_name, nodegroup_name, desired_size, min_size=None, max_size=None):
        """Scale a node group"""
        scaling_config = {'desiredSize': desired_size}
        if min_size is not None:
            scaling_config['minSize'] = min_size
        if max_size is not None:
            scaling_config['maxSize'] = max_size

        response = self.eks.update_nodegroup_config(
            clusterName=cluster_name,
            nodegroupName=nodegroup_name,
            scalingConfig=scaling_config
        )
        return response

# Usage example
if __name__ == '__main__':
    manager = EKSManager(region='us-east-1')

    # List clusters
    clusters = manager.list_clusters()
    print(f"Found {len(clusters)} clusters: {clusters}")

    # Get cluster details
    for cluster_name in clusters:
        info = manager.get_cluster_info(cluster_name)
        print(f"\nCluster: {info['name']}")
        print(f"  Status: {info['status']}")
        print(f"  Version: {info['version']}")

        # Get cost estimate
        costs = manager.get_cluster_cost_estimate(cluster_name)
        print(f"  Estimated monthly cost: ${costs['total']}")
        print(f"    Control plane: ${costs['control_plane']}")
        print(f"    Nodes: ${costs['nodes']}")
```

---

## 🪄 Pro Tip: Unifying Multi-Cloud Automation

If you want to orchestrate multiple clouds **from one codebase**, consider:

* **Pulumi** → Multi-cloud IaC in Python/TypeScript (wraps SDKs internally).
* **Terraform + Python SDKs** → Use Terraform for infra, Python SDKs for runtime ops.
* **Apache Libcloud** → Generic abstraction over many cloud APIs (good for basic compute/storage/network tasks).

---

Would you like me to create a **Python examples repo layout** (`multicloud-automation`) that includes minimal working scripts for each provider (AWS, GCP, OCI, Azure, Hetzner)?
That repo could complement your Week 2 “multi-cloud fluency” content perfectly.

