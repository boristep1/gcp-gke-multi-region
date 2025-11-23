Pub/Sub topic for scaling events
resource "google_pubsub_topic" "scaling" {
name = "gke-scaling-${var.region}"
project = var.project_id
}

Storage bucket for Cloud Function source
resource "google_storage_bucket" "function_source" {
name = "${var.project_id}-scaling-function-${var.region}"
project = var.project_id
location = var.region

uniform_bucket_level_access = true

lifecycle_rule {
condition {
age = 30
}
action {
type = "Delete"
}
}
}

Zip the function source
data "archive_file" "function_source" {
type = "zip"
output_path = "${path.module}/function.zip"

source {
content = file("${path.module}/function.py")
filename = "main.py"
}

source {
content = file("${path.module}/requirements.txt")
filename = "requirements.txt"
}
}

Upload function source to bucket
resource "google_storage_bucket_object" "function_zip" {
name = "function-${data.archive_file.function_source.output_md5}.zip"
bucket = google_storage_bucket.function_source.name
source = data.archive_file.function_source.output_path
}

Service account for Cloud Function
resource "google_service_account" "scaler" {
account_id = "gke-scaler-${var.region}"
display_name = "GKE Scaler Function for ${var.region}"
project = var.project_id
}

Grant GKE developer role
resource "google_project_iam_member" "scaler_gke" {
project = var.project_id
role = "roles/container.developer"
member = "serviceAccount:${google_service_account.scaler.email}"
}

Cloud Function
resource "google_cloudfunctions_function" "scaler" {
name = "gke-scaler-${var.region}"
project = var.project_id
region = var.region
runtime = "python39"
entry_point = "scale_deployment"

available_memory_mb = 256
timeout = 60

event_trigger {
event_type = "google.pubsub.topic.publish"
resource = google_pubsub_topic.scaling.id
}

source_archive_bucket = google_storage_bucket.function_source.name
source_archive_object = google_storage_bucket_object.function_zip.name

environment_variables = {
PROJECT_ID = var.project_id
CLUSTER_NAME = var.cluster_name
REGION = var.region
}

service_account_email = google_service_account.scaler.email
}

Cloud Scheduler jobs
resource "google_cloud_scheduler_job" "morning_scale_up" {
name = "gke-morning-scale-up-${var.region}"
project = var.project_id
region = var.region
description = "Scale up GKE deployment before morning rush hour"
schedule = var.morning_scale_up_schedule
time_zone = var.time_zone

pubsub_target {
topic_name = google_pubsub_topic.scaling.id
data = base64encode(jsonencode({
replicas = var.rush_hour_replicas
deployment = var.deployment_name
namespace = var.namespace
}))
}
}

resource "google_cloud_scheduler_job" "morning_scale_down" {
name = "gke-morning-scale-down-${var.region}"
project = var.project_id
region = var.region
description = "Scale down GKE deployment after morning rush"
schedule = var.morning_scale_down_schedule
time_zone = var.time_zone

pubsub_target {
topic_name = google_pubsub_topic.scaling.id
data = base64encode(jsonencode({
replicas = var.normal_replicas
deployment = var.deployment_name
namespace = var.namespace
}))
}
}

resource "google_cloud_scheduler_job" "evening_scale_up" {
name = "gke-evening-scale-up-${var.region}"
project = var.project_id
region = var.region
description = "Scale up GKE deployment before evening rush hour"
schedule = var.evening_scale_up_schedule
time_zone = var.time_zone

pubsub_target {
topic_name = google_pubsub_topic.scaling.id
data = base64encode(jsonencode({
replicas = var.rush_hour_replicas
deployment = var.deployment_name
namespace = var.namespace
}))
}
}

resource "google_cloud_scheduler_job" "evening_scale_down" {
name = "gke-evening-scale-down-${var.region}"
project = var.project_id
region = var.region
description = "Scale down GKE deployment after evening rush"
schedule = var.evening_scale_down_schedule
time_zone = var.time_zone

pubsub_target {
topic_name = google_pubsub_topic.scaling.id
data = base64encode(jsonencode({
replicas = var.baseline_replicas
deployment = var.deployment_name
namespace = var.namespace
}))
}
}

resource "google_cloud_scheduler_job" "weekend_scale_down" {
name = "gke-weekend-scale-down-${var.region}"
project = var.project_id
region = var.region
description = "Scale to minimal replicas for weekend"
schedule = var.weekend_schedule
time_zone = var.time_zone

pubsub_target {
topic_name = google_pubsub_topic.scaling.id
data = base64encode(jsonencode({
replicas = var.weekend_replicas
deployment = var.deployment_name
namespace = var.namespace
}))
}
}
