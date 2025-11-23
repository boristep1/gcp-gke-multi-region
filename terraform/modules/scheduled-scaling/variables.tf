variable "project_id" {
description = "GCP Project ID"
type = string
}

variable "region" {
description = "GCP region"
type = string
}

variable "cluster_name" {
description = "Name of the GKE cluster"
type = string
}

variable "deployment_name" {
description = "Name of the Kubernetes deployment to scale"
type = string
default = "transport-api"
}

variable "namespace" {
description = "Kubernetes namespace"
type = string
default = "default"
}

variable "time_zone" {
description = "Time zone for scheduler"
type = string
default = "Europe/London"
}

Replica counts
variable "rush_hour_replicas" {
description = "Number of replicas during rush hour"
type = number
default = 40
}

variable "normal_replicas" {
description = "Number of replicas during normal hours"
type = number
default = 10
}

variable "baseline_replicas" {
description = "Number of replicas during low traffic"
type = number
default = 5
}

variable "weekend_replicas" {
description = "Number of replicas on weekends"
type = number
default = 3
}

Schedules (cron format)
variable "morning_scale_up_schedule" {
description = "Cron schedule for morning scale up"
type = string
default = "45 6 * * 1-5" # 6:45 AM weekdays
}

variable "morning_scale_down_schedule" {
description = "Cron schedule for morning scale down"
type = string
default = "30 9 * * 1-5" # 9:30 AM weekdays
}

variable "evening_scale_up_schedule" {
description = "Cron schedule for evening scale up"
type = string
default = "45 16 * * 1-5" # 4:45 PM weekdays
}

variable "evening_scale_down_schedule" {
description = "Cron schedule for evening scale down"
type = string
default = "30 19 * * 1-5" # 7:30 PM weekdays
}

variable "weekend_schedule" {
description = "Cron schedule for weekend scaling"
type = string
default = "0 8 * * 6" # 8:00 AM Saturday
}

