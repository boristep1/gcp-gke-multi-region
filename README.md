# GKE Multi-Region Architecture with Advanced Scaling

A production-ready, multi-region GKE deployment with ESPv2 sidecar, scheduled pre-scaling, and comprehensive SRE controls for handling predictable traffic spikes.

## 🏗️ Architecture Overview

This solution implements a highly available, multi-region architecture using:

- **GKE Regional Clusters** (3 zones per region) for high availability
- **ESPv2 Sidecar** for API management within the cluster
- **Global Load Balancer** with NEGs for intelligent traffic routing
- **Horizontal Pod Autoscaler (HPA)** for reactive scaling
- **Scheduled Pre-Scaling** for proactive capacity management
- **Pod Disruption Budgets (PDB)** for reliability during updates
- **Priority Classes** for critical workload protection

                   ┌─────────────────────────────────────┐
                   │  Global External Load Balancer     │
                   │  (Anycast IP, SSL termination)     │
                   └──────────────┬──────────────────────┘
                                  │
                   ┌──────────────┴──────────────────────┐
                   │   Network Endpoint Groups           │
                   │   (pointing to GKE pods)            │
                   └──────────────┬──────────────────────┘
                                  │
          ┌───────────────────────┴───────────────────────────┐
          │                                                   │
  ┌───────────────────┐                             ┌───────────────────┐
  │  GKE REGIONAL A   │                             │  GKE REGIONAL B   │
  │  europe-west1     │                             │  us-central1      │
  │                   │                             │                   │
  │  ┌─────────────┐  │                             │  ┌─────────────┐  │
  │  │   Pod       │  │                             │  │   Pod       │  │
  │  │ ┌─────────┐ │  │                             │  │ ┌─────────┐ │  │
  │  │ │ ESPv2   │ │  │                             │  │ │ ESPv2   │ │  │
  │  │ │ Sidecar │ │  │                             │  │ │ Sidecar │ │  │
  │  │ └────┬────┘ │  │                             │  │ └────┬────┘ │  │
  │  │      │      │  │                             │  │      │      │  │
  │  │ ┌────▼────┐ │  │                             │  │ ┌────▼────┐ │  │
  │  │ │ Backend │ │  │                             │  │ │ Backend │ │  │
  │  │ │ App     │ │  │                             │  │ │ App     │ │  │
  │  │ └─────────┘ │  │                             │  │ └─────────┘ │  │
  │  └─────────────┘  │                             │  └─────────────┘  │
  │                   │                             │                   │
  │  3-zone cluster   │                             │  3-zone cluster   │
  └─────────┬─────────┘                             └─────────┬─────────┘
            │                                                 │
            │         ┌─────────────────────────┐            │
            └────────►│  Firestore / BigQuery   │◄───────────┘
                      │  (multi-region)         │
                      └─────────────────────────┘

## 🚀 Quick Start

### Prerequisites

- Google Cloud Project with billing enabled
- `gcloud` CLI installed and authenticated
- Terraform >= 1.0
- Helm >= 3.0
- kubectl >= 1.28

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/gcp-gke-multi-region.git
cd gcp-gke-multi-region
```

### 2. Deploy Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
# Get credentials for Europe cluster
gcloud container clusters get-credentials transport-cluster-europe-west1 \
  --region europe-west1 \
  --project YOUR_PROJECT_ID

# Get credentials for US cluster
gcloud container clusters get-credentials transport-cluster-us-central1 \
  --region us-central1 \
  --project YOUR_PROJECT_ID
```

### 4. Deploy Application with Helm

```bash
cd ../helm/transport-api

# Deploy to Europe cluster
kubectl config use-context gke_YOUR_PROJECT_ID_europe-west1_transport-cluster-europe-west1
helm install transport-api . -f values-production.yaml

# Deploy to US cluster
kubectl config use-context gke_YOUR_PROJECT_ID_us-central1_transport-cluster-us-central1
helm install transport-api . -f values-production.yaml
```

## 📋 Features

### ✅ High Availability

- Regional clusters spanning 3 zones
- Pod Disruption Budgets (80% minimum availability)
- Multi-cluster deployment across regions
- Automatic pod distribution across zones

### ✅ Advanced Scaling

- **HPA**: Reactive scaling based on CPU/memory (5-50 replicas)
- **Cluster Autoscaler**: Automatic node provisioning (3-30 nodes)
- **Scheduled Pre-Scaling**: Proactive scaling before rush hours
- **VPA**: Resource request optimization (recommendation mode)

### ✅ Scheduled Pre-Scaling (The Secret Weapon)

Automatically scales deployment before predictable traffic spikes:

```
06:45 AM → Scale to 40 replicas (before morning rush)
09:30 AM → Scale to 10 replicas (after morning rush)
04:45 PM → Scale to 40 replicas (before evening rush)
07:30 PM → Scale to 5 replicas (after evening rush)
```

**Cost savings**: ~65% compared to running 40 replicas 24/7

### ✅ Security & Compliance

- Workload Identity for pod authentication
- Network Policies for pod-to-pod communication
- Shielded GKE nodes
- Binary Authorization support
- Resource Quotas per namespace

### ✅ Observability

- Cloud Monitoring integration
- Managed Prometheus
- Custom dashboards
- Alerting for pod crashes, node exhaustion, high latency

## 📊 Scaling Strategy

### Traffic Pattern (Public Transport Workload)

| Time Period | Expected Load | Replica Count | Strategy |
|:------------|:--------------|:--------------|:---------|
| 00:00-06:45 | Minimal       |       5       | Baseline |
| 06:45-07:00 | Ramping up    |      40       | **Pre-scaled** |
| 07:00-09:00 | Peak (morning)|   40-50       | HPA active |
| 09:00-16:45 | Moderate      |      10       | Scaled down |
| 16:45-17:00 | Ramping up    |      40       | **Pre-scaled** |
| 17:00-19:00 | Peak (evening)|   40-50       | HPA active |
| 19:00-24:00 | Low           |       5       | Scaled down |

### Why Pre-Scaling Matters

**Without pre-scaling:**

- Users at 7:00 AM hit cold pods
- HPA takes 2-3 minutes to scale
- Node autoscaler adds another 3-5 minutes
- **Result**: 5-8 minutes of degraded performance

**With pre-scaling:**

- Pods are running at 6:45 AM
- Nodes are already provisioned
- **Result**: Zero latency spike, guaranteed capacity

## 🔧 Configuration

### Adjust Scaling Thresholds

Edit `helm/transport-api/values-production.yaml`:

```yaml
autoscaling:
  minReplicas: 5
  maxReplicas: 50
  targetCPUUtilization: 60
  targetMemoryUtilization: 80
```

### Modify Pre-Scaling Schedule

Edit `terraform/modules/scheduled-scaling/main.tf`:

```hcl
resource "google_cloud_scheduler_job" "morning_scale_up" {
  schedule  = "45 6 * * 1-5"  # 6:45 AM weekdays
  time_zone = "Europe/London"
  # ...
}
```

### Change Node Pool Configuration

Edit `terraform/modules/gke-cluster/node-pools.tf`:

```hcl
node_config {
  machine_type = "n2-standard-4"  # Change instance type
  disk_size_gb = 100
  # ...
}

autoscaling {
  min_node_count = 3
  max_node_count = 30
}
```

## 📖 Documentation

- [Architecture Details](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Scaling Strategy](docs/scaling-strategy.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🧪 Testing

### Validate Deployment

```bash
# Check pod status
kubectl get pods -n default

# Check HPA status
kubectl get hpa

# Check PDB status
kubectl get pdb

# Test the service
kubectl port-forward svc/transport-api 8080:80
curl http://localhost:8080/health
```

### Load Testing

```bash
# Install hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Run load test
hey -z 60s -c 100 -q 10 https://YOUR_LOAD_BALANCER_IP/v1/routes
```

### Trigger Manual Scaling

```bash
# Scale to 40 replicas
kubectl scale deployment/transport-api --replicas=40

# Watch the scaling
kubectl get pods -w
```

## 🔄 CI/CD

### GitOps with ArgoCD (Recommended)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create application
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: transport-api
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/gcp-gke-multi-region
    targetRevision: HEAD
    path: helm/transport-api
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## 💰 Cost Optimization

### Estimated Monthly Costs (Single Region)

| Component | Configuration | Monthly Cost |
|:----------|:--------------|:-------------|
| **GKE Cluster** | Regional (3 zones) | $73 |
| **Nodes (baseline)** | 3x n2-standard-4 | ~$350 |
| **Nodes (peak)** | Additional autoscaling | ~$150 |
| **Load Balancer** | Global HTTPS LB | ~$20 |
| **Networking** | Egress + inter-zone | ~$50 |
| **Monitoring** | Cloud Monitoring | ~$30 |
| **Total** | | **~$673/month** |

**With scheduled scaling**: Save ~$200/month by scaling down during off-peak hours

**Multi-region (2 clusters)**: ~$1,346/month

## 🛡️ SRE Best Practices

### Reliability Patterns Implemented

✅ **Pod Disruption Budgets**: Ensure 80% availability during updates
✅ **Priority Classes**: Protect critical pods during resource pressure
✅ **Liveness/Readiness Probes**: Automatic pod health management
✅ **Resource Requests/Limits**: Prevent resource starvation
✅ **Network Policies**: Restrict pod-to-pod communication
✅ **Topology Spread**: Distribute pods across zones

### Monitoring & Alerting

Pre-configured alerts for:

- Pod crash loops (>5 restarts)
- Node pool near capacity (>90%)
- High pod CPU/memory usage
- Deployment rollout failures
- HPA unable to scale

## 🧹 Cleanup

```bash
# Delete Helm releases
helm uninstall transport-api

# Destroy infrastructure
cd terraform
terraform destroy
```

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](LICENSE).

## 🆘 Support

- [GitHub Issues](https://github.com/yourusername/gcp-gke-multi-region/issues)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🎯 Use Cases

This architecture is ideal for:

- 🚌 Public transport systems with rush-hour patterns
- 🏦 Financial services with market hours
- 🎓 Educational platforms with class schedules
- 🏥 Healthcare systems with predictable appointment patterns
- 📺 Media streaming with scheduled content releases

---

**Built with ❤️ for production workloads requiring precise control and predictable performance**
