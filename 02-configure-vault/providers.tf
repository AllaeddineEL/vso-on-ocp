
data "terraform_remote_state" "setup" {
  backend = "local"

  config = {
    path = "../01-install-vault/terraform.tfstate"
  }
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  config_path = "~/.kube/config"
}
provider "kubectl" {
  config_path = "~/.kube/config"
}
provider "vault" {
  address = data.terraform_remote_state.setup.outputs.vault_url
  token   = data.terraform_remote_state.setup.outputs.vault_root_token
}
