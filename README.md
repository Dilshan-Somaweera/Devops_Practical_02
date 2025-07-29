# Task01 - GKE Cluster Setup

This Terraform configuration creates a Google Kubernetes Engine (GKE) cluster named "Task01" for Kubernetes deployments.

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** installed (>= 1.0)
3. **GCP Project** with billing enabled
4. **Required APIs** enabled:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

## Files Structure

```
├── main.tf              
├── variables.tf         
├── outputs.tf          
├── terraform.tfvars    
└── README.md           
```

## Quick Setup

### 1. Configure Project ID

Edit `terraform.tfvars` with your GCP project ID:
```hcl
project_id = "your-gcp-project-id"
```

### 2. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

Type `yes` when prompted to create the cluster.

## Accessing the Cluster

### 1. Get kubectl Configuration

After deployment, run the command from terraform output:

```bash
# Get the command
terraform output kubectl_config_command

# Example output:
# gcloud container clusters get-credentials Task01 --zone asia-south1-a --project your-project-id
```

### 2. Verify Access

```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

## Configuration

Default configuration:
- **Cluster Name**: Task01
- **Location**: asia-south1-a
- **Initial Nodes**: 1
- **Machine Type**: e2-small
- **HTTP Access**: Allowed on port 80

## Customization

To customize, modify variables in `terraform.tfvars`:

```hcl
project_id = "your-project-id"
cluster_name = "my-cluster"
initial_node_count = 3
machine_type = "e2-medium"
region = "us-central1"
zone = "us-central1-a"
```

## Cleanup

To destroy the cluster:

```bash
terraform destroy
```

**Warning**: This permanently deletes your cluster and all resources.

## Troubleshooting

**Permission Issues**:
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

**API Not Enabled**:
```bash
gcloud services enable container.googleapis.com compute.googleapis.com
```

**Check Cluster Status**:
```bash
gcloud container clusters describe Task01 --zone=asia-south1-a
```

# Task02 - Container Deployment

This task demonstrates containerized application deployment on Kubernetes using public container images with proper scaling and service exposure.

## Overview

- **Application**: Using public container image (Nginx or custom app)
- **Replicas**: Minimum 2 replicas for high availability
- **Service**: Exposed via LoadBalancer
- **Registry**: Public container registry (Docker Hub, etc.)

## Creating Your Own Docker Image (Optional)

If you want to create your own Docker image instead of using a public one:

1. **Fork the repository**: https://github.com/Dilshan-Somaweera/portfolio_with_githubactions.git
2. **Set GitHub Secrets**:
   - Go to your forked repo → Settings → Secrets and variables → Actions
   - Add `DOCKER_USERNAME` (your Docker Hub username)
   - Add `DOCKER_PASSWORD` (your Docker Hub password/token)
3. **Run GitHub Actions**:
   - Navigate to Actions tab in your repo
   - Run the workflow at: `.github/workflows/nextjs.yml`
   - This will build and push your image to Docker Hub
4. **Use your image** in the deployment.yaml file

## Files Structure

```
k8s-manifests/
├── deployment.yaml     # Application deployment with 2+ replicas
├── service.yaml        # Service to expose the application
└── README.md          # This file
```

## Prerequisites

1. **Kubernetes cluster** running (from Task01)
2. **kubectl** configured and connected to cluster
3. **Container image** available in public registry

## Deployment Steps

### 1. Verify Cluster Access

```bash
# Check cluster connection
kubectl cluster-info

# Verify nodes are ready
kubectl get nodes
```

### 2. Deploy Application

```bash
# Navigate to manifests directory
cd k8s-manifests/

# Apply deployment first
kubectl apply -f deployment.yaml

# Wait for pods to be ready, then apply service
kubectl apply -f service.yaml
```

### 3. Verify Deployment

```bash
# Check deployment status
kubectl get deployments

# Check pods (should show 2+ replicas)
kubectl get pods

# Check service
kubectl get services

# Get detailed deployment info
kubectl describe deployment <deployment-name>
```

## Accessing the Application

### LoadBalancer Service:

```bash
# Get service details and external IP
kubectl get service <service-name>

# Wait for EXTERNAL-IP (may take a few minutes)
# Status will change from <pending> to actual IP

# Access application
# http://<EXTERNAL-IP>:<PORT>
```

**Note**: LoadBalancer may take 2-5 minutes to provision external IP address.

## Verification Commands

### Check Application Health

```bash
# View application logs
kubectl logs -l app=<app-label>

# Check pod details
kubectl describe pod <pod-name>

# Test scaling
kubectl scale deployment <deployment-name> --replicas=3

# Verify scaling
kubectl get pods
```

### Port Forward (Alternative Access)

```bash
# Forward local port to service
kubectl port-forward service/<service-name> 8080:80

# Access via localhost
curl http://localhost:8080
# or open http://localhost:8080 in browser
```

## Troubleshooting

### Common Issues

**Pods not starting**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Service not accessible**:
```bash
kubectl get endpoints
kubectl describe service <service-name>
```

**Image pull errors**:
```bash
# Check if image exists and is accessible
kubectl describe pod <pod-name>
```

### Health Checks

```bash
# Check all resources
kubectl get all

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top pods
kubectl top nodes
```

## Cleanup

To remove the deployment (order matters):

```bash
# Delete service first
kubectl delete -f service.yaml

# Then delete deployment
kubectl delete -f deployment.yaml

# Verify cleanup
kubectl get all
```

## Configuration Details

### Deployment Features:
- **Replicas**: 2+ instances for availability
- **Image**: Public container registry image
- **Resource limits**: CPU/Memory constraints
- **Health checks**: Readiness and liveness probes

### Service Features:
- **Type**: LoadBalancer
- **Port mapping**: Internal to external port mapping
- **Selector**: Routes traffic to deployment pods
- **External access**: Provides external IP for internet access

## Monitoring

```bash
# Watch deployment status
kubectl get pods -w

# Monitor service endpoints
kubectl get endpoints -w

# Check resource utilization
kubectl top pods
```

## Scaling Operations

```bash
# Scale up
kubectl scale deployment <deployment-name> --replicas=5

# Scale down
kubectl scale deployment <deployment-name> --replicas=2

# Auto-scale (if HPA configured)
kubectl autoscale deployment <deployment-name> --cpu-percent=70 --min=2 --max=10
```

This completes Task02 - containerized application deployment with proper scaling and service exposure on Kubernetes.
