resource "vault_mount" "kvv2" {
  namespace   = "dev/backend"
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_policy" "kv" {
  namespace = "dev/backend"
  name      = "dev-backend-kv"
  policy    = <<EOT
path "${vault_mount.kvv2.path}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kv_secret_v2" "webapp" {
  namespace           = "dev/backend"
  mount               = vault_mount.kvv2.path
  name                = "webapp"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      username = "static-user",
      password = "static-password"
    }
  )
}
resource "kubectl_manifest" "vault-auth-kv" {
  validate_schema = false
  yaml_body       = <<YAML
  apiVersion: secrets.hashicorp.com/v1beta1
  kind: VaultAuth
  metadata:
    name: static-auth
    namespace: ${kubernetes_namespace.dev.metadata[0].name}
  spec:
    method: kubernetes
    mount: "dev-backend-auth-mount"
    kubernetes:
      role: "auth-role"
      serviceAccount: default
      audiences:
        - vault
  YAML
  depends_on = [
    helm_release.vso,
  ]
}

resource "kubectl_manifest" "kv-secret-create" {
  validate_schema = false
  yaml_body       = <<YAML
  apiVersion: secrets.hashicorp.com/v1beta1
  kind: VaultStaticSecret
  metadata:
    name: vault-kv-app
    namespace: "${kubernetes_namespace.dev.metadata[0].name}"
  spec:
    type: kv-v2

    # mount path
    mount: "${vault_mount.kvv2.path}"

    # path of the secret
    path: webapp

    # dest k8s secret
    destination:
      name: secretkv
      create: true

    # static secret refresh interval
    refreshAfter: 30s

    # Name of the CRD to authenticate to Vault
    vaultAuthRef: "${kubectl_manifest.vault-auth-kv.name}"
  YAML
  depends_on = [
    helm_release.vso
  ]
}
