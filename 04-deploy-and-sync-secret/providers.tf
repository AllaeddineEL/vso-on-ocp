
provider "vault" {

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
