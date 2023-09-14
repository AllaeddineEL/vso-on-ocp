
resource "vault_auth_backend" "dev_backend" {
  namespace = "dev/backend"
  path      = "dev-backend-auth-mount"
  type      = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "dev_backend" {
  namespace              = "dev/backend"
  backend                = vault_auth_backend.dev_backend.path
  kubernetes_host        = "https://kubernetes.default.svc"
  disable_iss_validation = true
}

# kubernetes auth roles
resource "vault_kubernetes_auth_backend_role" "dev_backend" {
  namespace                        = vault_auth_backend.dev_backend.namespace
  backend                          = vault_kubernetes_auth_backend_config.dev_backend.backend
  role_name                        = "auth-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["dev-backend"]
  token_period                     = 120
  token_policies = [
    "dev-backend-db",
    "dev-backend-kv"
  ]
  audience = "vault"
}

resource "vault_kubernetes_auth_backend_role" "operator" {
  namespace                        = vault_auth_backend.dev_backend.namespace
  backend                          = vault_kubernetes_auth_backend_config.dev_backend.backend
  role_name                        = "auth-role-operator"
  bound_service_account_names      = ["default-vso-operator"]
  bound_service_account_namespaces = ["vso"]
  token_period                     = 120
  token_policies = [
    "default-operator",
  ]
  audience = "vault"
}

