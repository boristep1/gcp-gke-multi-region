variable "project_id" {
description = "GCP Project ID"
type = string
}

variable "region" {
description = "GCP region for the cluster"
type = string
}

variable "environment" {
description = "Environment name (e.g., production, staging)"
type = string
default = "production"
}

variable "machine_type" {
description = "Machine type for GKE nodes"
type = string
default = "n2-standard-4"
}

variable "min_node_count" {
description = "Minimum number of nodes per zone"
type = number
default = 1
}

variable "max_node_count" {
description = "Maximum number of nodes per zone"
type = number
default = 10
}

variable "spot_max_node_count" {
description = "Maximum number of spot nodes per zone"
type = number
default = 5
}
