variable "orgs" {
  default = ["dev", "ops"]
}
variable "dev_tenants" {
  default = ["frontend", "backend"]
}
variable "ops_tenants" {
  default = ["data"]
}
variable "dev_org_admin_users" {
  default = ["dev-org-admin1", "dev-org-admin2"]
}

variable "ops_org_admin_users" {
  default = ["ops-org-admin1", "ops-org-admin2"]
}
variable "dev_backend_admin_users" {
  default = ["dev-backend-admin1", "dev-backend-admin2"]
}
variable "dev_backend_member_users" {
  default = ["dev-backend-member1", "dev-backend-member2"]
}
variable "dev_frontend_admin_users" {
  default = ["dev-frontend-admin1", "dev-frontend-admin2"]
}
variable "dev_frontend_member_users" {
  default = ["dev-frontend-member1", "dev-frontend-member2"]
}
variable "ops_data_admin_users" {
  default = ["ops-data-admin1", "ops-data-admin2"]
}
variable "ops_data_member_users" {
  default = ["ops-data-member1", "ops-data-member2"]
}
