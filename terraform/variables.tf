variable "project_id" {
description = "GCP Project ID"
type = string
}

variable "environment" {
description = "Environment name"
type = string
default = "production"
}

variable "machine_type" {
description = "GKE node machine type"
type = string
default = "n2-standard-4"
}

variable "min_node_count" {
description = "Minimum nodes per zone"
type = number
default = 1
}

variable "max_node_count" {
description = "Maximum nodes per zone"
type = number
default = 10
}

variable "deployment_name" {
description = "Kubernetes deployment name"
type = string
default = "transport-api"
}

variable "namespace" {
description = "Kubernetes namespace"
type = string
default = "default"
}

variable "rush_hour_replicas" {
description = "Replicas during rush hour"
type = number
default = 40
}

variable "normal_replicas" {
description = "Replicas during normal hours"
type = number
default = 10
}

variable "baseline_replicas" {
description = "Baseline replicas"
type = number
default = 5
}

variable "weekend_replicas" {
description = "Weekend replicas"
type = number
default = 3
}

variable "notification_email" {
description = "Email for alerts"
type = string
}
