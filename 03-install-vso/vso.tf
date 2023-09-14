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

# resource "kubectl_manifest" "vault-connection-default" {
#   validate_schema = false
#   yaml_body       = <<YAML
#   apiVersion: secrets.hashicorp.com/v1beta1
#   kind: VaultConnection
#   metadata:
#     name: default
#     namespace: ${kubernetes_namespace.vso.metadata[0].name}
#   spec:
#     address: http://vault.vault.svc.cluster.local:8200
#   YAML
# }
