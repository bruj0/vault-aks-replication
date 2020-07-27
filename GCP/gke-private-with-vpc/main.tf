locals {
  cluster_type = "private"
}

provider "google" {
  version = "~> 3.16.0"
  region  = var.region
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.4.0"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name           = var.subnetwork
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

data "google_compute_subnetwork" "subnetwork" {
  name       = var.subnetwork
  project    = var.project_id
  region     = var.region
  depends_on = [module.gcp-network]
}


module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version    = "v10.0.0"
  project_id = var.project_id
  name       = "${local.cluster_type}-${var.cluster_name_suffix}"
  regional   = true
  region     = var.region
  #zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
  // This craziness gets a plain network name from the reference link which is the
  // only way to force cluster creation to wait on network creation without a
  // depends_on link.  Tests use terraform 0.12.6, which does not have regex or regexall
  network = reverse(split("/", data.google_compute_subnetwork.subnetwork.network))[0]

  subnetwork                = data.google_compute_subnetwork.subnetwork.name
  ip_range_pods             = var.ip_range_pods_name
  ip_range_services         = var.ip_range_services_name
  create_service_account    = true
  enable_private_endpoint   = false
  enable_private_nodes      = true
  master_ipv4_cidr_block    = "172.16.0.0/28"
  default_max_pods_per_node = 100
  remove_default_node_pool  = true
  grant_registry_access     = true
  #The final count will be this value * zones
  initial_node_count = 1




  #Needed for Vault pod injector
  #firewall_inbound_ports = ["8080"]

  node_pools = [
    {
      name            = "pool-01"
      machine_type    = "n1-standard-4"
      min_count       = 1
      max_count       = 100
      local_ssd_count = 0
      disk_size_gb    = 100
      disk_type       = "pd-standard"
      image_type      = "COS"
      auto_repair     = true
      auto_upgrade    = true
      #service_account    = var.compute_engine_service_account
      preemptible        = true
      max_pods_per_node  = 100
      initial_node_count = 1
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
      display_name = "VPC"
    },
    {
      cidr_block   = "77.163.156.16/32",
      display_name = "bastion"
    },
  ]
}

data "google_client_config" "default" {
}
