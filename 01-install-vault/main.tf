
# resource "kubernetes_namespace" "vault" {
#   metadata {
#     annotations = {
#       name = "vault"
#     }
#     name = "vault"
#   }

# }

resource "kubectl_manifest" "vault_certs" {
  validate_schema = false
  yaml_body       = <<-EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vault-certs
  namespace: vault
spec:
  secretName: vault-certs
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: "vault.crc-vm.${var.sandbox_id}.instruqt.io"
  dnsNames:
    - "vault.crc-vm.${var.sandbox_id}.instruqt.io"
  EOF
  depends_on      = [kubectl_manifest.cluster_issuer]
}

# resource "kubernetes_secret_v1" "enterprise_license" {
#   metadata {
#     name      = "enterprise-license"
#     namespace = kubernetes_namespace.vault.metadata.0.name
#   }
#   data = {
#     "license" = var.vault_license
#   }
# }
resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = vault
  version          = "0.25.0"
  create_namespace = false
  values = [
    templatefile("${path.module}/templates/vault/vault.yaml", { vault_fqdn = "vault.crc-vm.${var.sandbox_id}.instruqt.io" })
  ]
  depends_on = [kubectl_manifest.vault_certs]
}

