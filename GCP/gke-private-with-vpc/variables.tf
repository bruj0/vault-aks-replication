variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "rodrigo-support"
}

variable "cluster_name_suffix" {
  description = "A suffix to append to the default cluster name"
  default     = "vault"
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "europe-west4"
}

variable "network" {
  description = "The VPC network to host the cluster in"
  default     = "gke01"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  default     = "gke-01"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "services"
}

variable "compute_engine_service_account" {
  description = "Service account to associate to the nodes in the cluster"
  default     = "gke-pool@rodrigo-support.iam.gserviceaccount.com"
}
