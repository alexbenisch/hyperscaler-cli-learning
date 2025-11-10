# Hyperscaler CLI Learning

A hands-on learning repository for mastering cloud provider CLI tools. This repo contains practical examples, exercises, and automation scripts for major cloud platforms.

## 🎯 Learning Objectives

- Master CLI tools for major cloud providers
- Understand infrastructure automation patterns
- Learn cloud-native best practices
- Build reusable scripts and templates
- Compare services across providers

## ☁️ Cloud Providers

### [AWS CLI](aws/)
**Amazon Web Services** - `aws`

- Compute (EC2, ECS, Lambda)
- Storage (S3, EBS)
- Networking (VPC, Route53)
- Kubernetes (EKS)
- IAM and Security

### [Azure CLI](azure/)
**Microsoft Azure** - `az`

- Compute (VMs, Container Instances, Functions)
- Storage (Blob Storage, Disks)
- Networking (VNet, DNS)
- Kubernetes (AKS)
- Identity (Azure AD)

### [Google Cloud CLI](gcp/)
**Google Cloud Platform** - `gcloud`, `gsutil`, `kubectl`

- Compute (Compute Engine, Cloud Run, Cloud Functions)
- Storage (Cloud Storage, Persistent Disks)
- Networking (VPC, Cloud DNS)
- Kubernetes (GKE)
- IAM and Security

### [Hetzner Cloud CLI](hetzner/)
**Hetzner Cloud** - `hcloud`

- Cloud Servers
- Volumes
- Networks
- Load Balancers
- Firewalls
- SSH Keys

### [Oracle Cloud CLI](oci/)
**Oracle Cloud Infrastructure** - `oci`

- Compute Instances
- Block Storage
- Virtual Cloud Networks
- Container Engine for Kubernetes (OKE)
- Identity and Access Management

## 📚 Repository Structure

```
hyperscaler-cli-learning/
├── aws/
│   ├── README.md           # AWS CLI guide
│   ├── setup/              # Installation & configuration
│   ├── compute/            # EC2, ECS, Lambda examples
│   ├── storage/            # S3, EBS examples
│   ├── networking/         # VPC, Route53 examples
│   ├── kubernetes/         # EKS examples
│   └── scripts/            # Automation scripts
├── azure/
│   ├── README.md           # Azure CLI guide
│   ├── setup/
│   ├── compute/
│   ├── storage/
│   ├── networking/
│   ├── kubernetes/
│   └── scripts/
├── gcp/
│   ├── README.md           # GCP CLI guide
│   ├── setup/
│   ├── compute/
│   ├── storage/
│   ├── networking/
│   ├── kubernetes/
│   └── scripts/
├── hetzner/
│   ├── README.md           # Hetzner CLI guide
│   ├── setup/
│   ├── servers/
│   ├── networking/
│   ├── storage/
│   └── scripts/
├── oci/
│   ├── README.md           # OCI CLI guide
│   ├── setup/
│   ├── compute/
│   ├── storage/
│   ├── networking/
│   ├── kubernetes/
│   └── scripts/
├── projects/               # Multi-cloud projects
│   ├── kubernetes-cluster/ # Deploy k8s on each provider
│   ├── object-storage/     # Compare object storage
│   └── cost-comparison/    # Price comparison tools
├── docs/
│   ├── comparison.md       # Service comparison matrix
│   ├── best-practices.md   # Cloud CLI best practices
│   └── cheatsheet.md       # Quick reference
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Linux/macOS terminal or WSL on Windows
- Basic understanding of cloud computing concepts
- Git installed
- Text editor (VS Code recommended)

### Installation

Each cloud provider section includes detailed installation instructions:

1. [AWS CLI Setup](aws/setup/)
2. [Azure CLI Setup](azure/setup/)
3. [Google Cloud CLI Setup](gcp/setup/)
4. [Hetzner CLI Setup](hetzner/setup/)
5. [Oracle Cloud CLI Setup](oci/setup/)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/hyperscaler-cli-learning.git
cd hyperscaler-cli-learning

# Start with your preferred cloud provider
cd aws  # or azure, gcp, hetzner, oci

# Follow the setup guide
cat README.md
```

## 📖 Learning Path

### Beginner

1. **Installation & Setup** - Install CLIs and configure credentials
2. **Basic Commands** - List resources, get info, create simple resources
3. **Resource Management** - Create, update, delete resources

### Intermediate

4. **Automation Scripts** - Bash/Python scripts for common tasks
5. **Infrastructure Patterns** - VPC, subnets, security groups
6. **Storage Operations** - Upload/download, backup, sync

### Advanced

7. **Kubernetes Deployment** - Deploy and manage k8s clusters
8. **Multi-Cloud Projects** - Build the same infrastructure on each provider
9. **Cost Optimization** - Monitor costs, optimize resources
10. **CI/CD Integration** - Use CLIs in pipelines

## 🎓 Learning Projects

### Project 1: Deploy a Web Application
Deploy the same web application on all five cloud providers and compare:
- Setup time
- Configuration complexity
- Performance
- Cost
- Management experience

### Project 2: Object Storage Comparison
Implement the same object storage workflow on each provider:
- Upload/download files
- Set permissions
- Enable versioning
- Configure lifecycle policies
- Compare pricing and features

### Project 3: Kubernetes Cluster
Deploy a production-ready Kubernetes cluster on each provider:
- Cluster creation
- Node pool management
- Network configuration
- Storage classes
- Load balancer setup
- Cost analysis

### Project 4: Disaster Recovery
Implement backup and disaster recovery:
- Automated backups
- Cross-region replication
- Restore procedures
- Testing and validation

## 📊 Service Comparison Matrix

| Service Type | AWS | Azure | GCP | Hetzner | OCI |
|--------------|-----|-------|-----|---------|-----|
| **Compute** | EC2 | Virtual Machines | Compute Engine | Cloud Servers | Compute Instances |
| **Containers** | ECS/EKS | AKS | GKE | - | OKE |
| **Serverless** | Lambda | Functions | Cloud Functions | - | Functions |
| **Object Storage** | S3 | Blob Storage | Cloud Storage | - | Object Storage |
| **Block Storage** | EBS | Managed Disks | Persistent Disks | Volumes | Block Volumes |
| **Load Balancer** | ELB/ALB | Load Balancer | Cloud Load Balancing | Load Balancers | Load Balancer |
| **DNS** | Route 53 | Azure DNS | Cloud DNS | DNS Console | DNS |
| **CLI Tool** | `aws` | `az` | `gcloud` | `hcloud` | `oci` |

## 🔧 Best Practices

### CLI Usage

- **Use profiles** for multiple accounts/projects
- **Enable command completion** for faster typing
- **Use output formats** (JSON, table, YAML) appropriately
- **Leverage filters** and queries to find specific resources
- **Script repetitive tasks** for automation

### Security

- **Never commit credentials** to git
- **Use environment variables** or credential files
- **Rotate access keys** regularly
- **Follow least privilege** principles
- **Enable MFA** where supported

### Cost Management

- **Tag all resources** for cost tracking
- **Use cost estimation** commands before creating resources
- **Clean up unused resources** regularly
- **Set up billing alerts**
- **Use spot/preemptible instances** for non-critical workloads

## 📝 Notes and Tips

- Each provider directory contains a `README.md` with specific guidance
- Example commands are provided with explanations
- Scripts include comments for learning
- Compare pricing before running expensive operations
- Use free tier offerings when available

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add examples or fix errors
4. Test your commands
5. Submit a pull request

## 📚 Resources

### Official Documentation
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Google Cloud CLI Documentation](https://cloud.google.com/sdk/gcloud)
- [Hetzner Cloud CLI Documentation](https://docs.hetzner.cloud/)
- [Oracle Cloud CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)

### Learning Resources
- AWS Training & Certification
- Microsoft Learn for Azure
- Google Cloud Skills Boost
- Hetzner Cloud Documentation
- Oracle Cloud Learning Library

## 📄 License

MIT License - Feel free to use these examples for learning purposes.

## 🎯 Goals

- [ ] Complete AWS CLI examples
- [ ] Complete Azure CLI examples
- [ ] Complete GCP CLI examples
- [ ] Complete Hetzner CLI examples
- [ ] Complete OCI CLI examples
- [ ] Build comparison matrix
- [ ] Create multi-cloud projects
- [ ] Write automation scripts
- [ ] Document cost comparisons
- [ ] Add CI/CD examples

---

**Note**: This is a learning repository. Always check pricing and clean up resources after experimentation to avoid unexpected costs.
