
resource "kubernetes_namespace" "vault" {
  metadata {
    annotations = {
      name = "vault"
    }
    name = "vault"
  }

}


resource "kubernetes_secret_v1" "enterprise_license" {
  metadata {
    name      = "enterprise-license"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }
  data = {
    "license" = var.vault_license
  }
}
resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = kubernetes_namespace.vault.metadata[0].name
  version          = "0.25.0"
  create_namespace = false
  values = [
    templatefile("${path.module}/templates/vault.yaml", { vault_fqdn = "https://vault.crc-vm.${var.sandbox_id}.instruqt.io", ent_license_secret_name = kubernetes_secret_v1.enterprise_license.metadata.0.name })
  ]
}

