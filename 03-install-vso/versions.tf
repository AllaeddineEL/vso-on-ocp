terraform {
  required_providers {

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.15.0"
    }

  }
}
