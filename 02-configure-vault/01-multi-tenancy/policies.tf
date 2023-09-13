resource "vault_policy" "admin_policy" {
  for_each  = vault_namespace.orgs
  namespace = each.value.path
  name      = "admin"
  policy    = file("policies/org-admin-policy.hcl")
}
resource "vault_policy" "dev_tenants_admin_policy" {
  for_each  = vault_namespace.dev_tenants
  namespace = each.value.path_fq
  name      = "admin"
  policy    = file("policies/tenant-admin-policy.hcl")
}
resource "vault_policy" "dev_tenants_member_policy" {
  for_each  = vault_namespace.dev_tenants
  namespace = each.value.path_fq
  name      = "member"
  policy    = file("policies/member-policy.hcl")
}

resource "vault_policy" "ops_tenants_admin_policy" {
  for_each  = vault_namespace.ops_tenants
  namespace = each.value.path_fq
  name      = "admin"
  policy    = file("policies/tenant-admin-policy.hcl")
}
resource "vault_policy" "ops_tenants_member_policy" {
  for_each  = vault_namespace.ops_tenants
  namespace = each.value.path_fq
  name      = "member"
  policy    = file("policies/member-policy.hcl")
}
