resource "vault_mount" "kvv2" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_policy" "kv" {
  namespace = local.namespace
  name      = "${local.auth_policy}-kv"
  policy    = <<EOT
path "${vault_mount.kvv2.path}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kv_secret_v2" "webapp" {
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
