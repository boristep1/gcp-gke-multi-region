# VPC Network
resource "google_compute_network" "gke_network" {
name = "gke-network-${var.region}"
project = var.project_id
auto_create_subnetworks = false
routing_mode = "REGIONAL"
}

# Subnet for GKE nodes
resource "google_compute_subnetwork" "gke_subnet" {
name = "gke-subnet-${var.region}"
project = var.project_id
region = var.region
network = google_compute_network.gke_network.id
ip_cidr_range = "10.0.0.0/24"


# Secondary ranges for pods and services
secondary_ip_range {
range_name = "pods"
ip_cidr_range = "10.1.0.0/16"
}
secondary_ip_range {
range_name = "services"
ip_cidr_range = "10.2.0.0/20"
}

# Enable Private Google Access
private_ip_google_access = true

# Flow logs for debugging
log_config {
aggregation_interval = "INTERVAL_5_SEC"
flow_sampling = 0.5
metadata = "INCLUDE_ALL_METADATA"
}
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
name = "gke-router-${var.region}"
project = var.project_id
region = var.region
network = google_compute_network.gke_network.id
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
name = "gke-nat-${var.region}"
project = var.project_id
router = google_compute_router.router.name
region = var.region
nat_ip_allocate_option = "AUTO_ONLY"
source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

log_config {
enable = true
filter = "ERRORS_ONLY"
}
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "allow_internal" {
name = "gke-allow-internal-${var.region}"
project = var.project_id
network = google_compute_network.gke_network.name

allow {
protocol = "tcp"
ports = ["0-65535"]
}

allow {
protocol = "udp"
ports = ["0-65535"]
}

allow {
protocol = "icmp"
}

source_ranges = [
"10.0.0.0/24", # Node subnet
"10.1.0.0/16", # Pod subnet
"10.2.0.0/20", # Service subnet
]
}

# Firewall rule for health checks
resource "google_compute_firewall" "allow_health_checks" {
name = "gke-allow-health-checks-${var.region}"
project = var.project_id
network = google_compute_network.gke_network.name

allow {
protocol = "tcp"
}

source_ranges = [
"35.191.0.0/16",
"130.211.0.0/22",
]

target_tags = ["gke-node"]
}
