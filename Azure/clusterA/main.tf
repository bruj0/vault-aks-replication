provider "azurerm" {
  features {}
}
variable "name" {
  default = "rodrigo-aks"
}

variable "location" {
  description = "Name of file holding tfstate, should be unique for every tf module"
  type        = string
  default     = "West Europe"
}

variable "k8s_version_prefix" {
  description = "Minor Version of Kubernetes to target (ex: 1.14)"
  type        = string
  default     = "1.15"
}

data "azurerm_kubernetes_service_versions" "current" {
  location       = var.location
  version_prefix = var.k8s_version_prefix
}

locals {
  aks_version = data.azurerm_kubernetes_service_versions.current.latest_version
}

######
provider "azuread" {
  version = ">=0.6.0"
}

# =============================================
# Service Principle
# =============================================

resource "azuread_application" "aks_service_principle" {
  name                       = "${var.name}-aks-sp"
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

resource "azuread_service_principal" "aks_service_principle" {
  application_id = azuread_application.aks_service_principle.application_id
}

resource "random_password" "aks_service_principle" {
  length  = 16
  special = true
}

resource "azuread_service_principal_password" "aks_service_principle" {
  service_principal_id = azuread_service_principal.aks_service_principle.id
  value                = random_password.aks_service_principle.result
  end_date             = "2020-12-01T01:02:03Z"
}

# =============================================
# main
# =============================================
# Using rhythmicthech repo because the official Azure implementation doesnt support the `network_profile` block.

module "aks" {
  #source = "../"
  source = "github.com/rhythmictech/terraform-azurerm-aks?ref=v5.1.0"

  prefix             = var.name
  kubernetes_version = local.aks_version
  CLIENT_ID          = azuread_application.aks_service_principle.application_id
  CLIENT_SECRET      = random_password.aks_service_principle.result
  location           = var.location
  network_profile = {
    network_plugin     = "azure"
    network_policy     = null
    dns_service_ip     = null
    docker_bridge_cidr = null
    pod_cidr           = null
    service_cidr       = null
    load_balancer_sku  = "standard"
  }
  default_node_pool = {
    name                  = "nodepool"
    vm_size               = "standard_f2"
    enable_auto_scaling   = true
    os_disk_size_gb       = 50
    type                  = "VirtualMachineScaleSets"
    max_count             = 3
    min_count             = 1
    enable_node_public_ip = false
  }
  tags = {
    environment = "Demo"
    Owner       = "rodrigo@hashicorp.com"
  }
}

# =============================================
# outputs
# =============================================
