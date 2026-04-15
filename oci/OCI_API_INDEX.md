# OCI API Reference Index

Base URL: https://docs.oracle.com/en-us/iaas/api/
OCI CLI version: 3.79.0

Use this index to find the right CLI namespace and API docs URL.
For OKE/k8s work, the primary services are: `ce`, `network`, `iam`, `lb`, `compute`.

---

## Core Infrastructure

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci compute` | Compute Service | https://docs.oracle.com/en-us/iaas/api/#/en/iaas/ |
| `oci compute-management` | Compute Management (instance pools) | https://docs.oracle.com/en-us/iaas/api/#/en/iaas/ |
| `oci network` | Networking (VCN, subnets, IGW, route tables) | https://docs.oracle.com/en-us/iaas/api/#/en/iaas/ |
| `oci lb` | Load Balancing | https://docs.oracle.com/en-us/iaas/api/#/en/loadbalancer/ |
| `oci nlb` | Network Load Balancer | https://docs.oracle.com/en-us/iaas/api/#/en/networkloadbalancer/ |
| `oci dns` | DNS | https://docs.oracle.com/en-us/iaas/api/#/en/dns/ |
| `oci network-firewall` | Network Firewall | https://docs.oracle.com/en-us/iaas/api/#/en/network-firewall/ |

## Kubernetes / Containers

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci ce` | **OKE - Kubernetes Engine** | https://docs.oracle.com/en-us/iaas/api/#/en/containerengine/ |
| `oci container-instances` | Container Instances | https://docs.oracle.com/en-us/iaas/api/#/en/container-instances/ |
| `oci container-registry` | Container Registry (OCIR) | https://docs.oracle.com/en-us/iaas/api/#/en/registry/ |
| `oci artifacts` | Artifacts and Container Images | https://docs.oracle.com/en-us/iaas/api/#/en/artifacts/ |

## Identity & Security

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci iam` | Identity and Access Management | https://docs.oracle.com/en-us/iaas/api/#/en/identity/ |
| `oci identity-domains` | Identity Domains | https://docs.oracle.com/en-us/iaas/api/#/en/identity-domains/ |
| `oci vault` | Vault Secret Management | https://docs.oracle.com/en-us/iaas/api/#/en/secretmgmt/ |
| `oci secrets` | Vault Secret Retrieval | https://docs.oracle.com/en-us/iaas/api/#/en/secrets/ |
| `oci kms` | Key Management | https://docs.oracle.com/en-us/iaas/api/#/en/key/ |
| `oci cloud-guard` | Cloud Guard & Security Zones | https://docs.oracle.com/en-us/iaas/api/#/en/cloud-guard/ |
| `oci waf` | Web Application Firewall | https://docs.oracle.com/en-us/iaas/api/#/en/waf/ |
| `oci bastion` | Bastion | https://docs.oracle.com/en-us/iaas/api/#/en/bastion/ |

## Storage

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci os` | Object Storage | https://docs.oracle.com/en-us/iaas/api/#/en/objectstorage/ |
| `oci bv` | Block Volume | https://docs.oracle.com/en-us/iaas/api/#/en/iaas/ |
| `oci fs` | File Storage | https://docs.oracle.com/en-us/iaas/api/#/en/filestorage/ |

## Database

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci db` | Database Service (Exadata, Base DB) | https://docs.oracle.com/en-us/iaas/api/#/en/database/ |
| `oci mysql` | MySQL Database Service | https://docs.oracle.com/en-us/iaas/api/#/en/mysql-database/ |
| `oci nosql` | NoSQL Database | https://docs.oracle.com/en-us/iaas/api/#/en/nosql-database/ |
| `oci psql` | PostgreSQL | https://docs.oracle.com/en-us/iaas/api/#/en/postgresql/ |

## Observability / Monitoring

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci monitoring` | Monitoring (metrics, alarms) | https://docs.oracle.com/en-us/iaas/api/#/en/monitoring/ |
| `oci logging` | Logging Management | https://docs.oracle.com/en-us/iaas/api/#/en/logging-management/ |
| `oci apm-traces` | APM Trace Explorer | https://docs.oracle.com/en-us/iaas/api/#/en/apm-trace-explorer/ |
| `oci ons` | Notifications | https://docs.oracle.com/en-us/iaas/api/#/en/notification/ |

## DevOps / Platform

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci devops` | DevOps (CI/CD pipelines) | https://docs.oracle.com/en-us/iaas/api/#/en/devops/ |
| `oci fn` | Functions (serverless) | https://docs.oracle.com/en-us/iaas/api/#/en/functions/ |
| `oci api-gateway` | API Gateway | https://docs.oracle.com/en-us/iaas/api/#/en/api-gateway/ |
| `oci resource-manager` | Resource Manager (Terraform stacks) | https://docs.oracle.com/en-us/iaas/api/#/en/resourcemanager/ |
| `oci streaming` | Streaming (Kafka-compatible) | https://docs.oracle.com/en-us/iaas/api/#/en/streaming/ |

## Cost / Governance

| CLI Command | Service | API Docs |
|-------------|---------|----------|
| `oci budgets` | Budgets | https://docs.oracle.com/en-us/iaas/api/#/en/budgets/ |
| `oci usage-api` | Usage (cost reporting) | https://docs.oracle.com/en-us/iaas/api/#/en/usage/ |
| `oci limits` | Service Limits | https://docs.oracle.com/en-us/iaas/api/#/en/limits/ |

---

## How to Look Up a Specific API

When you need details on a specific operation:

```bash
# List subcommands for a service
oci ce --help
oci network --help

# List operations for a resource
oci ce cluster --help
oci network vcn --help

# Get full option details for a command
oci ce cluster create --help
```

For REST API details (request/response schemas), go directly to the service doc URL above and search for the operation name.

---

## OKE-Specific API Quick Reference

All under `oci ce`:

```bash
oci ce cluster create/get/update/delete/list
oci ce cluster create-kubeconfig
oci ce cluster update-endpoint-config
oci ce node-pool create/get/delete/list/update
oci ce node-pool-options get
oci ce work-request get/list
oci ce work-request-error list
oci ce work-request-log-entry list
```
