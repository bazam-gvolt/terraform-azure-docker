terraform {
  backend "remote" {
    organization = "gvolt"
    workspaces {
      name = "terraform-azure-docker"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

module "networking" {
  source          = "./modules/networking"
  environment     = var.environment
  location        = var.location
  location_prefix = var.location_prefix
  tags            = var.tags
}

module "aks" {
  source              = "./modules/aks"
  environment         = var.environment
  location            = var.location
  location_prefix     = var.location_prefix
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.aks_subnet_id
  tags                = var.tags
}

module "wazuh" {
  source = "./modules/wazuh"
  depends_on = [module.aks]
}

module "monitoring" {
  source = "./modules/monitoring"
  depends_on = [module.aks]
}

environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars

modules/
├── aks/
│   └── locals.tf
├── monitoring/
│   └── locals.tf
├── networking/
│   └── locals.tf
└── wazuh/
    └── locals.tf