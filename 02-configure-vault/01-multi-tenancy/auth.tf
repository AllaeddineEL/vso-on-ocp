#--------------------------------
# Enable userpass auth method
#--------------------------------

resource "vault_auth_backend" "root_userpass" {
  type = "userpass"
}
resource "random_password" "super_admin_user" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "super_admin_user" {
  depends_on           = [vault_auth_backend.root_userpass]
  path                 = "auth/userpass/users/super-admin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.super_admin_policy.name}"],
  "password": "${random_password.super_admin_user.result}"
}
EOT
}
resource "vault_auth_backend" "orgs_userpass" {
  for_each  = vault_namespace.orgs
  type      = "userpass"
  namespace = each.value.path_fq
}

# Create users and passowrds
resource "random_password" "dev_org_admin_users" {
  for_each         = toset(var.dev_org_admin_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "vault_generic_endpoint" "dev_org_admin_users" {
  for_each             = toset(var.dev_org_admin_users)
  depends_on           = [vault_auth_backend.orgs_userpass["dev"]]
  namespace            = vault_namespace.orgs["dev"].path
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.admin_policy["dev"].name}"],
  "password": "${random_password.dev_org_admin_users[each.key].result}"
}
EOT
}

resource "random_password" "ops_org_admin_users" {
  for_each         = toset(var.ops_org_admin_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "ops_org_admin_users" {
  for_each             = toset(var.ops_org_admin_users)
  depends_on           = [vault_auth_backend.orgs_userpass["ops"]]
  namespace            = vault_namespace.orgs["ops"].path
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.admin_policy["ops"].name}"],
  "password": "${random_password.ops_org_admin_users[each.key].result}"
}
EOT
}

resource "vault_auth_backend" "dev_tenants" {
  for_each  = vault_namespace.dev_tenants
  type      = "userpass"
  namespace = each.value.path_fq
}
resource "random_password" "dev_backend_admin_users" {
  for_each         = toset(var.dev_backend_admin_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "dev_backend_admin_users" {
  for_each             = toset(var.dev_backend_admin_users)
  depends_on           = [vault_auth_backend.dev_tenants["backend"]]
  namespace            = vault_namespace.dev_tenants["backend"].path_fq
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.dev_tenants_admin_policy["backend"].name}"],
  "password": "${random_password.dev_backend_admin_users[each.key].result}"
}
EOT
}

resource "random_password" "dev_backend_member_users" {
  for_each         = toset(var.dev_backend_member_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "dev_backend_member_users" {
  for_each             = toset(var.dev_backend_member_users)
  depends_on           = [vault_auth_backend.dev_tenants["backend"]]
  namespace            = vault_namespace.dev_tenants["backend"].path_fq
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.dev_tenants_member_policy["backend"].name}"],
  "password": "${random_password.dev_backend_member_users[each.key].result}"
}
EOT
}



resource "random_password" "dev_frontend_admin_users" {
  for_each         = toset(var.dev_frontend_admin_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "dev_frontend_admin_users" {
  for_each             = toset(var.dev_frontend_admin_users)
  depends_on           = [vault_auth_backend.dev_tenants["frontend"]]
  namespace            = vault_namespace.dev_tenants["frontend"].path_fq
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.dev_tenants_admin_policy["frontend"].name}"],
  "password": "${random_password.dev_frontend_admin_users[each.key].result}"
}
EOT
}

resource "random_password" "dev_frontend_member_users" {
  for_each         = toset(var.dev_frontend_member_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "vault_generic_endpoint" "dev_frontend_member_users" {
  for_each             = toset(var.dev_frontend_member_users)
  depends_on           = [vault_auth_backend.dev_tenants["frontend"]]
  namespace            = vault_namespace.dev_tenants["frontend"].path_fq
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": [ "default","${vault_policy.dev_tenants_member_policy["frontend"].name}"],
  "password": "${random_password.dev_frontend_member_users[each.key].result}"
}
EOT
}

locals {
  dev_backend_admin_passwd = [for pwd in random_password.dev_backend_admin_users : nonsensitive(pwd.result)]
  dev_org_admin_passwd     = [for pwd in random_password.dev_org_admin_users : nonsensitive(pwd.result)]
}
output "dev_backend_admin_creds" {
  value = zipmap(var.dev_backend_admin_users, local.dev_backend_admin_passwd)
  #sensitive = true
}
output "dev_org_admin_creds" {
  value = zipmap(var.dev_org_admin_users, local.dev_org_admin_passwd)
  #sensitive = true
}
output "super_admin_creds" {
  value = zipmap(["super-admin"], [nonsensitive(random_password.super_admin_user.result)])
  #sensitive = true
}
