locals {
  # db locals
  postgres_host = "${data.kubernetes_service.postgres.metadata[0].name}.${helm_release.postgres.namespace}.svc.cluster.local:${data.kubernetes_service.postgres.spec[0].port[0].port}"
  db_creds_path = "creds/${var.db_role}"
}

resource "helm_release" "postgres" {
  namespace        = "dev-backend"
  name             = "postgres"
  create_namespace = false
  wait             = true
  wait_for_jobs    = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  set {
    name  = "auth.audit.logConnections"
    value = "true"
  }

}



data "kubernetes_secret" "postgres" {
  metadata {
    namespace = helm_release.postgres.namespace
    name      = "postgres-postgresql"
  }
}

# canary datasource: ensures that the postgres service exists, and provides the configured port.
data "kubernetes_service" "postgres" {
  metadata {
    namespace = helm_release.postgres.namespace
    name      = "${helm_release.postgres.name}-${helm_release.postgres.chart}"
  }
}

resource "vault_database_secrets_mount" "db" {
  namespace                 = "dev/backend"
  path                      = "dev-backend-db"
  default_lease_ttl_seconds = 15

  postgresql {
    name              = "postgres"
    username          = "postgres"
    password          = data.kubernetes_secret.postgres.data["postgres-password"]
    connection_url    = "postgresql://{{username}}:{{password}}@${local.postgres_host}/postgres?sslmode=disable"
    verify_connection = false
    allowed_roles = [
      "dev-backend-postgres",
    ]
  }
}

resource "vault_database_secret_backend_role" "postgres" {
  namespace = "dev/backend"
  backend   = vault_database_secrets_mount.db.path
  name      = "dev-backend-postgres"
  db_name   = vault_database_secrets_mount.db.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]
}

resource "vault_policy" "db" {
  namespace = "dev/backend"
  name      = "dev-backend-db"
  policy    = <<EOT
path "${vault_database_secrets_mount.db.path}/creds/${vault_database_secret_backend_role.postgres.name}" {
  capabilities = ["read"]
}
EOT
}
