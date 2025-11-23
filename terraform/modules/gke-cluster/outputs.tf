output "cluster_name" {
description = "Name of the GKE cluster"
value = google_container_cluster.regional.name
}

output "cluster_endpoint" {
description = "Endpoint of the GKE cluster"
value = google_container_cluster.regional.endpoint
sensitive = true
}

output "cluster_ca_certificate" {
description = "CA certificate of the GKE cluster"
value = google_container_cluster.regional.master_auth[0].cluster_ca_certificate
sensitive = true
}

output "network_name" {
description = "Name of the VPC network"
value = google_compute_network.gke_network.name
}

output "subnet_name" {
description = "Name of the subnet"
value = google_compute_subnetwork.gke_subnet.name
}

output "workload_identity_sa_email" {
description = "Email of the Workload Identity service account"
value = google_service_account.workload_identity.email
}

output "node_sa_email" {
description = "Email of the node service account"
value = google_service_account.gke_nodes.email
}
