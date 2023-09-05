resource "vault_namespace" "default" {
  count = length(local.tenants)
  path  = local.tenants[count.index]

}
resource "kubernetes_namespace" "default" {
  count = length(local.tenants)
  metadata {
    name = local.tenants[count.index]
  }
}
