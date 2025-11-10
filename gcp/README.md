# Google Cloud CLI Learning

Learn to use `gcloud`, `gsutil`, and `kubectl` to manage Google Cloud Platform infrastructure.

## Installation & Configuration

```bash
# Install (Linux)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install (macOS)
brew install google-cloud-sdk

# Initialize
gcloud init

# Login
gcloud auth login

# Set project
gcloud config set project PROJECT_ID

# Set region/zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## Compute Engine

```bash
# List images
gcloud compute images list

# Create VM
gcloud compute instances create my-instance \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-micro \
  --zone=us-central1-a

# List instances
gcloud compute instances list

# SSH into instance
gcloud compute ssh my-instance

# Stop/start/delete
gcloud compute instances stop my-instance
gcloud compute instances start my-instance
gcloud compute instances delete my-instance
```

## Cloud Storage

```bash
# Create bucket
gsutil mb gs://my-unique-bucket-name

# Upload file
gsutil cp file.txt gs://my-bucket/

# Download file
gsutil cp gs://my-bucket/file.txt .

# List buckets
gsutil ls

# List objects
gsutil ls gs://my-bucket/

# Delete bucket
gsutil rm -r gs://my-bucket
```

## GKE (Kubernetes)

```bash
# Create cluster
gcloud container clusters create my-cluster \
  --num-nodes=2 \
  --machine-type=e2-medium

# Get credentials
gcloud container clusters get-credentials my-cluster

# List clusters
gcloud container clusters list

# Delete cluster
gcloud container clusters delete my-cluster
```

Check full documentation at: https://cloud.google.com/sdk/docs
