
locals {
  # db locals
  postgres_host = "${data.kubernetes_service.postgres.metadata[0].name}.${helm_release.postgres.namespace}.svc.cluster.local:${data.kubernetes_service.postgres.spec[0].port[0].port}"

}
resource "kubectl_manifest" "vault-auth-default" {
  validate_schema = false
  yaml_body       = <<YAML
  apiVersion: secrets.hashicorp.com/v1beta1
  kind: VaultAuth
  metadata:
    name: default
    namespace: dev-backend
  spec:
    method: kubernetes
    mount: "dev-backend-auth-mount"
    namespace: "dev/backend"
    kubernetes:
      role: "dev-backend-postgres"
      serviceAccount: default
      audiences:
        - vault
  YAML
}

resource "kubectl_manifest" "vault-dynamic-secret" {
  validate_schema = false
  yaml_body       = <<YAML
  apiVersion: secrets.hashicorp.com/v1beta1
  kind: VaultDynamicSecret
  metadata:
    name: vso-db-demo
    namespace: dev-backend
  spec:
    vaultAuthRef: ${kubectl_manifest.vault-auth-default.name}
    namespace: "dev/backend"
    mount: "dev-backend-db"
    path: "creds/dev-backend-postgres"
    destination:
      create: false
      name: ${kubernetes_secret.db.metadata[0].name}
    rolloutRestartTargets:
      - kind: Deployment
        name: vso-db-demo 
  YAML
}

resource "kubectl_manifest" "vault-dynamic-secret-create" {
  validate_schema = false
  yaml_body       = <<YAML
  apiVersion: secrets.hashicorp.com/v1beta1
  kind: VaultDynamicSecret
  metadata:
    name: vso-db-demo-create
    namespace: dev-backend
  spec:
    vaultAuthRef: ${kubectl_manifest.vault-auth-default.name}
    namespace: "dev/backend"
    mount: "dev-backend-db"
    path: "creds/dev-backend-postgres"
    destination:
      create: true
      name: vso-db-demo-created
    rolloutRestartTargets:
      - kind: Deployment
        name: vso-db-demo 
  YAML
}

resource "kubernetes_secret" "db" {
  metadata {
    name      = "vso-db-demo"
    namespace = "dev-backend"
  }
}

resource "kubernetes_deployment" "example" {
  metadata {
    name      = "vso-db-demo"
    namespace = "dev-backend"
    labels = {
      test = "vso-db-demo"
    }
  }

  spec {
    replicas = 3

    strategy {
      rolling_update {
        max_unavailable = "1"
      }
    }

    selector {
      match_labels = {
        test = "vso-db-demo"
      }
    }

    template {
      metadata {
        labels = {
          test = "vso-db-demo"
        }
      }

      spec {
        volume {
          name = "secrets"
          secret {
            secret_name = kubernetes_secret.db.metadata[0].name
          }
        }
        container {
          image = "postgres:latest"
          name  = "demo"
          command = [
            "sh", "-c", "while : ; do psql postgresql://$PGUSERNAME@postgres-postgresql.dev-backend.svc.cluster.local:5432/postgres?sslmode=disable -c 'select 1;' ; echo $PGPASSWORD ;sleep 5; done"
          ]

          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "PGUSERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "username"
              }
            }
          }

          volume_mount {
            name       = "secrets"
            mount_path = "/etc/secrets"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "64Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
