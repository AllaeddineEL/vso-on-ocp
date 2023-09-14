terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.15.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}
