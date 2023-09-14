resource "kubernetes_namespace" "vso" {
  metadata {
    annotations = {
      name = "vso"
    }
    name = "vso"
  }
}
resource "helm_release" "vso" {
  name             = "vso"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = kubernetes_namespace.vso.metadata[0].name
  version          = "0.2.0"
  create_namespace = false
  values = [
    file("${path.module}/templates/values.yaml")
  ]

}

resource "kubernetes_service_account" "operator" {
  metadata {
    namespace = kubernetes_namespace.vso.metadata[0].name
    name      = "default-vso-operator"
  }
}
