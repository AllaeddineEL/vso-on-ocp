
data "google_client_config" "default" {}
data "google_container_cluster" "demo" {
  name = "demo"
}

data "terraform_remote_state" "setup" {
  backend = "local"

  config = {
    path = "../01-setup/vault/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.demo.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.demo.master_auth.0.cluster_ca_certificate)
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.region
}
provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  host                   = "https://${data.google_container_cluster.demo.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.demo.master_auth.0.cluster_ca_certificate)
}
provider "kubectl" {
  host                   = "https://${data.google_container_cluster.demo.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.demo.master_auth.0.cluster_ca_certificate)
}
provider "vault" {
  address = data.terraform_remote_state.setup.outputs.vault_url
  token   = data.terraform_remote_state.setup.outputs.vault_root_token
}
