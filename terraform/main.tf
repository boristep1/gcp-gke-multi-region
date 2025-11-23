terraform {
required_version = ">= 1.0"

required_providers {
google = {
source = "hashicorp/google"
version = "~> 5.0"
}
google-beta = {
source = "hashicorp/google-beta"
version = "~> 5.0"
}
kubernetes = {
source = "hashicorp/kubernetes"
version = "~> 2.23"
}
helm = {
source = "hashicorp/helm"
version = "~> 2.11"
}
}

backend "gcs" {
bucket = "YOUR_TERRAFORM_STATE_BUCKET"
prefix = "gke/prod"
}
}

provider "google" {
project = var.project_id
}

provider "google-beta" {
project = var.project_id
}

# Enable required APIs
resource "google_project_service" "required_apis" {
for_each = toset([
"container.googleapis.com",
"compute.googleapis.com",
"monitoring.googleapis.com",
"logging.googleapis.com",
"cloudscheduler.googleapis.com",
"cloudfunctions.googleapis.com",
"pubsub.googleapis.com",
"serviceusage.googleapis.com",
])

service = each.key
disable_on_destroy = false
}

# Deploy GKE cluster in Europe
module "gke_europe" {
source = "./modules/gke-cluster"

project_id = var.project_id
region = "europe-west1"
environment = var.environment
machine_type = var.machine_type
min_node_count = var.min_node_count
max_node_count = var.max_node_count

depends_on = [google_project_service.required_apis]
}

# Deploy GKE cluster in US
module "gke_us" {
source = "./modules/gke-cluster"

project_id = var.project_id
region = "us-central1"
environment = var.environment
machine_type = var.machine_type
min_node_count = var.min_node_count
max_node_count = var.max_node_count

depends_on = [google_project_service.required_apis]
}

# Scheduled scaling for Europe cluster
module "scheduled_scaling_europe" {
source = "./modules/scheduled-scaling"

project_id = var.project_id
region = "europe-west1"
cluster_name = module.gke_europe.cluster_name
deployment_name = var.deployment_name
namespace = var.namespace
time_zone = "Europe/London"

rush_hour_replicas = var.rush_hour_replicas
normal_replicas = var.normal_replicas
baseline_replicas = var.baseline_replicas
weekend_replicas = var.weekend_replicas

depends_on = [module.gke_europe]
}

# Scheduled scaling for US cluster
module "scheduled_scaling_us" {
source = "./modules/scheduled-scaling"

project_id = var.project_id
region = "us-central1"
cluster_name = module.gke_us.cluster_name
deployment_name = var.deployment_name
namespace = var.namespace
time_zone = "America/Chicago"

rush_hour_replicas = var.rush_hour_replicas
normal_replicas = var.normal_replicas
baseline_replicas = var.baseline_replicas
weekend_replicas = var.weekend_replicas

depends_on = [module.gke_us]
}

# Monitoring
module "monitoring" {
source = "./modules/monitoring"

project_id = var.project_id
notification_email = var.notification_email

clusters = {
europe = module.gke_europe.cluster_name
us = module.gke_us.cluster_name
}

depends_on = [
module.gke_europe,
module.gke_us,
]
}
