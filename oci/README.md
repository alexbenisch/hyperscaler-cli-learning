# Oracle Cloud CLI Learning

Learn to use the `oci` CLI to manage Oracle Cloud Infrastructure.

## Installation & Configuration

```bash
# Install (Linux/macOS)
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Setup config
oci setup config

# Test connection
oci iam region list
```

## Compute

```bash
# List shapes (instance types)
oci compute shape list --compartment-id COMPARTMENT_ID

# Create instance
oci compute instance launch \
  --availability-domain AD-1 \
  --compartment-id COMPARTMENT_ID \
  --shape VM.Standard.E2.1.Micro \
  --image-id IMAGE_ID \
  --subnet-id SUBNET_ID

# List instances
oci compute instance list --compartment-id COMPARTMENT_ID

# Stop/start/terminate
oci compute instance action --instance-id INSTANCE_ID --action STOP
oci compute instance action --instance-id INSTANCE_ID --action START
oci compute instance terminate --instance-id INSTANCE_ID
```

## Object Storage

```bash
# Create bucket
oci os bucket create --name my-bucket --compartment-id COMPARTMENT_ID

# Upload file
oci os object put --bucket-name my-bucket --file file.txt

# Download file
oci os object get --bucket-name my-bucket --name file.txt --file downloaded.txt

# List objects
oci os object list --bucket-name my-bucket
```

Check full documentation at: https://docs.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm
