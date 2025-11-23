output "gke_clusters" {
description = "GKE cluster information"
value = {
europe = {
name = module.gke_europe.cluster_name
endpoint = module.gke_europe.cluster_endpoint
}
us = {
name = module.gke_us.cluster_name
endpoint = module.gke_us.cluster_endpoint
}
}
sensitive = true
}

output "workload_identity_emails" {
description = "Workload Identity service account emails"
value = {
europe = module.gke_europe.workload_identity_sa_email
us = module.gke_us.workload_identity_sa_email
}
}

output "kubectl_commands" {
description = "Commands to configure kubectl"
value = {
europe = "gcloud container clusters get-credentials ${module.gke_europe.cluster_name} --region europe-west1 --project ${var.project_id}"
us = "gcloud container clusters get-credentials ${module.gke_us.cluster_name} --region us-central1 --project ${var.project_id}"
}
}