# Transport API Helm Chart

This Helm chart deploys the Transport API with ESPv2 sidecar to GKE.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.0+
- GKE cluster with Workload Identity enabled

## Installation

### Install with default values

```bash
helm install transport-api .
Install with production values
helm install transport-api . -f values-production.yaml
Install to specific namespace
kubectl create namespace production
helm install transport-api . -n production -f values-production.yaml
Configuration
Key Parameters
Parameter	Description	Default
app.replicas	Initial replica count	5
app.image.repository	Container image repository	europe-west1-docker.pkg.dev/...
app.image.tag	Container image tag	latest
autoscaling.minReplicas	Minimum replicas for HPA	5
autoscaling.maxReplicas	Maximum replicas for HPA	50
esp.enabled	Enable ESPv2 sidecar	true
esp.service	Cloud Endpoints service name	transport.endpoints...
Override Values
Create a custom values-custom.yaml:

app:
  replicas: 10
  image:
    tag: "v2.0.0"

autoscaling:
  minReplicas: 10
  maxReplicas: 100
Install with custom values:

helm install transport-api . -f values-custom.yaml
Upgrade
# Upgrade with new image
helm upgrade transport-api . --set app.image.tag=v1.1.0

# Upgrade with new values file
helm upgrade transport-api . -f values-production.yaml
Uninstall
helm uninstall transport-api
Testing
Template rendering
# Render templates without installing
helm template transport-api .

# Render with specific values
helm template transport-api . -f values-production.yaml
Dry run
helm install transport-api . --dry-run --debug
Monitoring
Check deployment status
kubectl get deployment transport-api
kubectl get pods -l app=transport-api
kubectl get hpa transport-api
kubectl get pdb transport-api
View logs
# Application logs
kubectl logs -l app=transport-api -c transport-api

# ESPv2 logs
kubectl logs -l app=transport-api -c esp
Troubleshooting
Pods not starting
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c transport-api
HPA not scaling
kubectl describe hpa transport-api
kubectl top pods -l app=transport-api
Service not accessible
kubectl get svc transport-api
kubectl describe svc transport-api
