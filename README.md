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

# Task 03 - Calico Setup

## Overview
This section demonstrates the implementation of Calico CNI (Container Network Interface) on a Kubernetes cluster deployed on Google Cloud Platform. The setup includes installing Calico, configuring network policies, and testing traffic isolation between pods.

## Infrastructure Details
- **Platform**: Google Cloud Platform (GCP)
- **VM Instance Type**: e2-standard-2 (2 vCPU, 8GB RAM per instance)
- **Kubernetes Cluster**: Self-managed cluster following manual setup
- **CNI Plugin**: Calico v3.26.1

## Prerequisites
- Kubernetes cluster running on GCP
- kubectl configured and connected to the cluster
- Administrative access to the cluster nodes

## Installation Steps

### 1. Cluster Setup
The Kubernetes cluster was created following the guide from [Creating a Kubernetes cluster step by step](https://medium.com/@brunosquassoni/creating-a-kubernetes-cluster-step-by-step-bd9ae3c85275).

### 2. Calico Installation
Calico was installed using the official Tigera documentation from [Calico Kubernetes Quickstart](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart).

#### Install Calico CRDs and Components
```bash
# Apply Calico Custom Resource Definitions
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/crds.yaml

# Install calicoctl CLI tool
sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.26.1/calicoctl -o calicoctl
sudo chmod +x calicoctl
sudo mv calicoctl /usr/local/bin/

# Verify installation
calicoctl version

# Configure kubeconfig for calicoctl
export KUBECONFIG=/home/sft2022viduaka/.kube/config
```

### 3. Network Policy Testing Setup

#### Create Test Namespace
```bash
kubectl create namespace calico-policy-ns
```

#### Deploy Test Applications
The following manifests are deployed to test network policies:

1. **nginx-deployment.yaml** - Nginx web server deployment
2. **nginx-service.yaml** - Service to expose Nginx
3. **busybox-pod.yaml** - BusyBox pod for testing connectivity

```bash
# Deploy Nginx application
kubectl apply -f nginx-deployment.yaml
kubectl get deployment -n calico-policy-ns

# Deploy Nginx service
kubectl apply -f nginx-service.yaml
kubectl get services -n calico-policy-ns

# Deploy BusyBox test pod
kubectl apply -f busybox-pod.yaml
kubectl get pods -n calico-policy-ns
```

#### Verify Initial Connectivity
```bash
# Get pod details including IP addresses
kubectl get pods -n calico-policy-ns nginx-7698bdd78b-f25kg -o wide

# Test connectivity from BusyBox to Nginx (should work initially)
kubectl -n calico-policy-ns exec -it access -- wget -O - 10.60.1.10
```

### 4. Network Policy Implementation

#### Apply Traffic Blocking Policy
```bash
# Apply network policy to block traffic to Nginx
calicoctl apply -f blocktraffictonginx.yaml

# Verify policy is applied
calicoctl get networkpolicy -n calico-policy-ns
```

#### Test Policy Enforcement
```bash
# Test connectivity after policy application (should fail/timeout)
kubectl -n calico-policy-ns exec -it access -- wget -O - 10.60.1.10
```

## Network Policy Configuration

The network policies demonstrate:

1. **Traffic Isolation**: Blocking unauthorized access to specific pods
2. **Namespace-level Security**: Controlling traffic flow within namespaces
3. **Label-based Selection**: Using Kubernetes labels for policy targeting

### Policy Files Location
All network policy YAML files are available in the repository at:
```
https://github.com/Dilshan-Somaweera/Devops_Practical_02/tree/main/k8s-manifests/Task03
```

## Testing Results

### Before Network Policy
- BusyBox pod can successfully access Nginx service
- Network connectivity works as expected
- wget command returns Nginx default page

### After Network Policy
- Traffic to Nginx is blocked as per policy rules
- wget command fails or times out
- Network isolation is successfully enforced

## Key Components

### Deployed Resources
- **Namespace**: `calico-policy-ns`
- **Deployment**: Nginx web server with 2 replicas
- **Service**: NodePort/ClusterIP service for Nginx
- **Pod**: BusyBox pod for connectivity testing
- **NetworkPolicy**: Calico network policy for traffic control

### Network Policy Features Demonstrated
1. **Ingress Rules**: Controlling incoming traffic to pods
2. **Pod Selection**: Using labels to target specific pods
3. **Traffic Blocking**: Denying access from unauthorized sources
4. **Policy Enforcement**: Real-time traffic filtering

## Verification Commands

```bash
# Check Calico installation status
kubectl get pods -n kube-system | grep calico

# View network policies
calicoctl get networkpolicy --all-namespaces

# Check pod connectivity
kubectl get pods -n calico-policy-ns -o wide

# Test network connectivity
kubectl -n calico-policy-ns exec -it <busybox-pod> -- wget -O - <nginx-service-ip>

# View Calico node status
calicoctl node status
```

## Troubleshooting

### Common Issues
1. **Policy Not Applied**: Ensure calicoctl is properly configured with kubeconfig
2. **Connectivity Issues**: Verify pod IPs and service endpoints
3. **DNS Resolution**: Check if service discovery is working properly

### Debug Commands
```bash
# Check Calico system pods
kubectl get pods -n kube-system -l k8s-app=calico-node

# View detailed network policy
calicoctl get networkpolicy <policy-name> -o yaml

# Check pod logs
kubectl logs -n calico-policy-ns <pod-name>
```

## Best Practices Implemented

1. **Namespace Isolation**: Using dedicated namespace for testing
2. **Label-based Policies**: Implementing policies based on Kubernetes labels
3. **Gradual Testing**: Testing connectivity before and after policy application
4. **Policy Validation**: Verifying policy enforcement through practical tests

## Next Steps

1. Implement more granular network policies
2. Add ingress controller integration
3. Set up monitoring for network policy violations
4. Implement network policy automation using GitOps

## References

- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico Network Policy](https://docs.tigera.io/calico/latest/network-policy/)

---
**Note**: This setup demonstrates basic Calico network policy functionality. For production environments, consider implementing more comprehensive security policies and monitoring solutions.

# Task 04 - Monitoring & Observability

## Overview
This section demonstrates the implementation of a comprehensive monitoring and observability solution using Prometheus and Grafana on Kubernetes. The setup includes deploying NGINX with custom metrics exposure, configuring Prometheus to scrape application metrics, and visualizing the data through Grafana dashboards.

The monitoring environment was set up following the guide: [A Hands-on Guide to Kubernetes Monitoring using Prometheus & Grafana](https://medium.com/@muppedaanvesh/a-hands-on-guide-to-kubernetes-monitoring-using-prometheus-grafana-%EF%B8%8F-b0e00b1ae039)

## Prerequisites
- Kubernetes cluster running and accessible via kubectl
- Helm 3.x installed
- Administrative access to the cluster
- Prometheus and Grafana stack deployed following [this comprehensive guide](https://medium.com/@muppedaanvesh/a-hands-on-guide-to-kubernetes-monitoring-using-prometheus-grafana-%EF%B8%8F-b0e00b1ae039)

## Environment Setup
The Prometheus and Grafana monitoring stack was installed using the kube-prometheus-stack Helm chart as detailed in the referenced Medium article. This provides:
- Prometheus Operator for managing Prometheus instances
- Grafana with pre-configured dashboards
- AlertManager for handling alerts
- Node Exporter for system metrics
- ServiceMonitor CRDs for service discovery

## Architecture Components
- **Prometheus**: Metrics collection and storage (deployed via kube-prometheus-stack)
- **Grafana**: Data visualization and dashboarding (deployed via kube-prometheus-stack)
- **NGINX**: Sample application with metrics exposure
- **NGINX Prometheus Exporter**: Sidecar container for metrics conversion
- **ServiceMonitor**: Prometheus service discovery configuration
- **Prometheus Operator**: Manages Prometheus instances and configurations
## Files Structure
```
https://github.com/Dilshan-Somaweera/Devops_Practical_02/tree/main/monitoring/
```

### Configuration Files
- `custom-values.yaml` - Helm values for Prometheus/Grafana stack
- `nginx-config.yaml` - NGINX configuration with metrics endpoint
- `nginx-exporter-deployment.yaml` - NGINX + Exporter deployment
- `nginx-exporter-service.yaml` - Service to expose NGINX and metrics
- `nginx-servicemonitor.yaml` - Prometheus scraping configuration

## Implementation Steps

### 1. Deploy NGINX Configuration
Apply the NGINX configuration that exposes the `/stub_status` endpoint for metrics scraping:

```bash
kubectl apply -f nginx-config.yaml
```

**What this does:**
- Creates a ConfigMap with custom NGINX configuration
- Enables the `/stub_status` endpoint for internal metrics
- Mounts the configuration into the NGINX container

### 2. Deploy NGINX with Prometheus Exporter
Deploy the main application with the metrics exporter as a sidecar:

```bash
kubectl apply -f nginx-exporter-deployment.yaml
```

**Architecture:**
- **NGINX Container**: Serves web traffic and exposes `/stub_status`
- **NGINX Prometheus Exporter**: Sidecar container that:
  - Fetches metrics from `http://localhost/stub_status`
  - Converts them to Prometheus format
  - Exposes metrics on port `9113`

### 3. Create Service for Metrics Exposure
Expose the deployment via a ClusterIP service:

```bash
kubectl apply -f nginx-exporter-service.yaml
```

**Service Configuration:**
- Port `80`: NGINX web traffic
- Port `9113`: Prometheus metrics endpoint

**Verification:**
```bash
kubectl get endpoints nginx-exporter-service -n default
```
You should see both ports (`80`, `9113`) mapped to the pod.

### 4. Configure Prometheus Service Discovery
Apply the ServiceMonitor to enable automatic metrics scraping:

```bash
kubectl apply -f nginx-servicemonitor.yaml
```

**Key Configuration:**
- `release: kube-prometheus-stack` matches Prometheus deployment labels
- Scrape interval: 15 seconds
- Target port: `9113` (metrics endpoint)

### 5. Verify Prometheus Target Discovery
Access Prometheus UI and verify the target:

1. Open Prometheus: `http://<external-ip>:30090`
2. Navigate to **Status > Targets**
3. Confirm `nginx-exporter` appears as **UP** target

### 6. Configure Grafana Dashboard
Set up visualization in Grafana:

1. Open Grafana: `http://<external-ip>:31959`
2. Go to **Dashboards > Import**
3. Use dashboard ID: `12708` (NGINX Exporter dashboard)
4. Select `Prometheus` as datasource
5. Click **Import**

## Technical Flow Explanation

### 🔧 How NGINX Monitoring Works

#### 1. Metrics Exposure (`nginx-config.yaml`)
- Custom NGINX configuration enables `/stub_status` endpoint
- Exposes internal metrics:
  - Active connections
  - Requests per second
  - Reading/writing/waiting connections
- Configuration packaged as ConfigMap and mounted to container

#### 2. Sidecar Pattern (`nginx-exporter-deployment.yaml`)
- **Two containers in one pod:**
  - `nginx`: Web server with metrics endpoint
  - `nginx-prometheus-exporter`: Metrics conversion service
- Shared network namespace allows exporter to access NGINX via `localhost`
- Exporter converts `/stub_status` to Prometheus format

#### 3. Service Discovery (`nginx-exporter-service.yaml`)
- ClusterIP service provides stable endpoint
- Exposes both application (80) and metrics (9113) ports
- Enables Prometheus to discover and scrape metrics

#### 4. Automatic Scraping (`nginx-servicemonitor.yaml`)
- ServiceMonitor configures Prometheus scraping behavior
- Selector matches service labels for automatic discovery
- Defines scrape interval and target port

#### 5. Data Flow Summary
```
[nginx-config.yaml] ➝ [nginx container] exposes /stub_status
                    ➝ [nginx-prometheus-exporter] reads stub_status
                    ➝ [nginx-exporter-service.yaml] exposes port 9113
                    ➝ [nginx-servicemonitor.yaml] tells Prometheus to scrape 9113
                    ➝ [Prometheus] stores metrics
                    ➝ [Grafana] visualizes via dashboards
```

## Verification Commands

### Check Deployment Status
```bash
# Verify pods are running
kubectl get pods -l app=nginx-exporter

# Check service configuration
kubectl get svc nginx-exporter-service

# Verify service endpoints
kubectl get endpoints nginx-exporter-service

# Check ServiceMonitor
kubectl get servicemonitor nginx-exporter-monitor
```

### Debug and Testing
```bash
# Check exporter logs
kubectl logs <nginx-exporter-pod-name> -c exporter

# Port forward to test metrics endpoint
kubectl port-forward svc/nginx-exporter-service 9113:9113

# Test metrics endpoint directly
curl http://localhost:9113/metrics

# Check NGINX logs
kubectl logs <nginx-exporter-pod-name> -c nginx
```

## Metrics Available

### NGINX Stub Status Metrics
- `nginx_connections_active`: Active client connections
- `nginx_connections_accepted_total`: Total accepted connections
- `nginx_connections_handled_total`: Total handled connections
- `nginx_http_requests_total`: Total HTTP requests
- `nginx_connections_reading`: Connections reading request headers
- `nginx_connections_writing`: Connections writing responses
- `nginx_connections_waiting`: Idle connections waiting for requests

### System Metrics (via Node Exporter)
- CPU usage per node
- Memory utilization
- Disk I/O statistics
- Network traffic
- Pod resource consumption

## Grafana Dashboard Features

### NGINX Exporter Dashboard (ID: 12708)
- **Request Rate**: HTTP requests per second
- **Connection States**: Active, reading, writing, waiting
- **Traffic Throughput**: Bytes sent/received
- **Response Codes**: HTTP status code distribution
- **Uptime Monitoring**: Service availability

### Custom Panels Available
- Real-time connection monitoring
- Request rate trends
- Error rate tracking
- Performance metrics visualization

## Troubleshooting

### Common Issues

#### 1. ServiceMonitor Not Discovered
- Verify label selector matches service labels
- Check namespace configuration
- Ensure Prometheus has proper RBAC permissions

#### 2. Metrics Not Appearing
- Confirm `/stub_status` endpoint is accessible
- Check exporter container logs
- Verify port forwarding and curl tests

#### 3. Grafana Dashboard Empty
- Ensure Prometheus is scraping targets successfully
- Verify datasource configuration
- Check metric names in queries

### Debug Steps
```bash
# Check Prometheus configuration
kubectl get prometheus -o yaml

# Verify ServiceMonitor labels
kubectl describe servicemonitor nginx-exporter-monitor

# Test connectivity to metrics endpoint
kubectl exec -it <nginx-pod> -c exporter -- wget -O- localhost:9113/metrics

# Check Prometheus targets API
curl http://<prometheus-url>/api/v1/targets
```

## Best Practices Implemented

1. **Sidecar Pattern**: Efficient metrics collection without modifying main application
2. **Service Discovery**: Automatic target discovery using ServiceMonitor
3. **Configuration Management**: Using ConfigMaps for application configuration
4. **Resource Labeling**: Proper labeling for service discovery and organization
5. **Separation of Concerns**: Distinct files for different components

## Performance Considerations

- **Scrape Interval**: Balanced at 15 seconds for real-time monitoring
- **Resource Limits**: Appropriate CPU/memory limits for exporter sidecar
- **Metric Retention**: Configured retention period in Prometheus
- **Dashboard Efficiency**: Optimized queries to prevent Grafana overload

## Security Considerations

- **Internal Networking**: Metrics endpoints only accessible within cluster
- **RBAC**: Proper permissions for ServiceMonitor discovery
- **Network Policies**: Restricted access to metrics endpoints
- **Authentication**: Grafana secured with proper authentication

## Monitoring Scope

### Application Level
- NGINX performance metrics
- Request/response patterns
- Error rates and status codes
- Connection handling efficiency

### Infrastructure Level
- Node resource utilization
- Pod performance metrics
- Network traffic patterns
- Storage usage statistics

## Next Steps

1. **Alerting**: Implement Prometheus AlertManager for proactive monitoring
2. **Custom Metrics**: Add application-specific business metrics
3. **Log Aggregation**: Integrate with ELK stack for comprehensive observability
4. **Distributed Tracing**: Add Jaeger for request tracing
5. **SLA Monitoring**: Configure SLI/SLO dashboards

## References

- [A Hands-on Guide to Kubernetes Monitoring using Prometheus & Grafana](https://medium.com/@muppedaanvesh/a-hands-on-guide-to-kubernetes-monitoring-using-prometheus-grafana-%EF%B8%8F-b0e00b1ae039) - Primary setup guide followed
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [NGINX Prometheus Exporter](https://github.com/nginxinc/nginx-prometheus-exporter)
- [Kubernetes ServiceMonitor](https://prometheus-operator.dev/docs/operator/design/#servicemonitor)

---
**Note**: This monitoring setup provides a foundation for production-grade observability. Consider scaling and security requirements for production deployments.