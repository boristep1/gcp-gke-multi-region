# Primary node pool for application workloads
resource "google_container_node_pool" "primary" {
name = "primary-pool"
location = var.region
cluster = google_container_cluster.regional.name
project = var.project_id

initial_node_count = 1

autoscaling {
min_node_count = var.min_node_count
max_node_count = var.max_node_count
location_policy = "BALANCED"
}

management {
auto_repair = true
auto_upgrade = true
}

node_config {
machine_type = var.machine_type
disk_size_gb = 100
disk_type = "pd-standard"

# Use Container-Optimized OS
image_type = "COS_CONTAINERD"

# Service account
service_account = google_service_account.gke_nodes.email
oauth_scopes = [
  "https://www.googleapis.com/auth/cloud-platform"
]

# Workload Identity
workload_metadata_config {
  mode = "GKE_METADATA"
}

# Labels
labels = {
  environment = var.environment
  workload    = "application"
  pool        = "primary"
}

# Tags for firewall rules
tags = ["gke-node", "transport-api"]

# Metadata
metadata = {
  disable-legacy-endpoints = "true"
}

# Shielded instance config
shielded_instance_config {
  enable_secure_boot          = true
  enable_integrity_monitoring = true
}

# Resource reservations
reservation_affinity {
  consume_reservation_type = "NO_RESERVATION"
}
}

upgrade_settings {
max_surge = 1
max_unavailable = 0
strategy = "SURGE"
}

lifecycle {
ignore_changes = [initial_node_count]
}
}

# Spot instance pool for non-critical workloads
resource "google_container_node_pool" "spot" {
name = "spot-pool"
location = var.region
cluster = google_container_cluster.regional.name
project = var.project_id

initial_node_count = 0

autoscaling {
min_node_count = 0
max_node_count = var.spot_max_node_count
location_policy = "BALANCED"
}

management {
auto_repair = true
auto_upgrade = true
}

node_config {
machine_type = var.machine_type
disk_size_gb = 100
disk_type = "pd-standard"
spot = true

image_type = "COS_CONTAINERD"

service_account = google_service_account.gke_nodes.email
oauth_scopes = [
  "https://www.googleapis.com/auth/cloud-platform"
]

workload_metadata_config {
  mode = "GKE_METADATA"
}

labels = {
  environment = var.environment
  workload    = "batch"
  pool        = "spot"
}

tags = ["gke-node", "spot"]

# Taint to prevent regular pods from scheduling here
taint {
  key    = "cloud.google.com/gke-spot"
  value  = "true"
  effect = "NO_SCHEDULE"
}

metadata = {
  disable-legacy-endpoints = "true"
}

shielded_instance_config {
  enable_secure_boot          = true
  enable_integrity_monitoring = true
}
}

upgrade_settings {
max_surge = 1
max_unavailable = 0
}

lifecycle {
ignore_changes = [initial_node_count]
}
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
account_id = "gke-nodes-${var.region}"
display_name = "GKE node service account for ${var.region}"
project = var.project_id
}

# IAM bindings for node service account
resource "google_project_iam_member" "gke_nodes_log_writer" {
project = var.project_id
role = "roles/logging.logWriter"
member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
project = var.project_id
role = "roles/monitoring.metricWriter"
member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
project = var.project_id
role = "roles/monitoring.viewer"
member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_resource_metadata_writer" {
project = var.project_id
role = "roles/stackdriver.resourceMetadata.writer"
member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Workload Identity binding for application
resource "google_service_account" "workload_identity" {
account_id = "transport-api-${var.region}"
display_name = "Workload Identity SA for transport-api in ${var.region}"
project = var.project_id
}

resource "google_service_account_iam_member" "workload_identity_binding" {
service_account_id = google_service_account.workload_identity.name
role = "roles/iam.workloadIdentityUser"
member = "serviceAccount:${var.project_id}.svc.id.goog[default/transport-api-sa]"
}

# Grant Firestore access to workload identity
resource "google_project_iam_member" "workload_firestore" {
project = var.project_id
role = "roles/datastore.user"
member = "serviceAccount:${google_service_account.workload_identity.email}"
}

# Grant BigQuery access to workload identity
resource "google_project_iam_member" "workload_bigquery" {
project = var.project_id
role = "roles/bigquery.dataViewer"
member = "serviceAccount:${google_service_account.workload_identity.email}"
}

