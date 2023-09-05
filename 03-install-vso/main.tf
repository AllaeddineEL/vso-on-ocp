resource "kubernetes_namespace" "dev" {
  metadata {
    name = local.k8s_namespace
  }
}

resource "vault_namespace" "test" {
  count = var.vault_enterprise ? 1 : 0
  path  = "${local.name_prefix}-ns"
}
