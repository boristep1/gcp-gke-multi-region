resource "google_container_cluster" "regional" {
name = "transport-cluster-${var.region}"
location = var.region
project = var.project_id

# We manage our own node pool
remove_default_node_pool = true
initial_node_count = 1

# Network configuration
network = google_compute_network.gke_network.id
subnetwork = google_compute_subnetwork.gke_subnet.id

# IP allocation for pods and services
ip_allocation_policy {
cluster_secondary_range_name = "pods"
services_secondary_range_name = "services"
}

# Enable Workload Identity
workload_identity_config {
workload_pool = "${var.project_id}.svc.id.goog"
}

# Release channel for automatic updates
release_channel {
channel = "REGULAR"
}

# Maintenance window
maintenance_policy {
daily_maintenance_window {
start_time = "03:00"
}
}

# Cluster addons
addons_config {
http_load_balancing {
disabled = false
}

horizontal_pod_autoscaling {
  disabled = false
}

network_policy_config {
  disabled = false
}

gcp_filestore_csi_driver_config {
  enabled = false
}

gcs_fuse_csi_driver_config {
  enabled = false
}
}

# Network policy
network_policy {
enabled = true
provider = "PROVIDER_UNSPECIFIED"
}

# Logging configuration
logging_config {
enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

# Monitoring configuration
monitoring_config {
enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]

managed_prometheus {
  enabled = true
}
}

# Binary authorization
binary_authorization {
evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
}

# Datapath provider (use advanced networking)
datapath_provider = "ADVANCED_DATAPATH"

# Private cluster configuration (optional but recommended)
private_cluster_config {
enable_private_nodes = true
enable_private_endpoint = false
master_ipv4_cidr_block = "172.16.0.0/28"
}

# Master authorized networks (optional)
master_authorized_networks_config {
cidr_blocks {
cidr_block = "0.0.0.0/0"
display_name = "All networks"
}
}

# Resource labels
resource_labels = {
environment = var.environment
managed-by = "terraform"
region = var.region
}
}

