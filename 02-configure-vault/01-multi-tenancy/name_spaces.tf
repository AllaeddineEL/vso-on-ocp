resource "vault_namespace" "orgs" {
  for_each = toset(var.orgs)
  path     = each.key
}
resource "vault_namespace" "dev_tenants" {
  for_each  = toset(var.dev_tenants)
  path      = each.key
  namespace = vault_namespace.orgs["dev"].path
}
resource "vault_namespace" "ops_tenants" {
  for_each  = toset(var.ops_tenants)
  path      = each.key
  namespace = vault_namespace.orgs["ops"].path
}
