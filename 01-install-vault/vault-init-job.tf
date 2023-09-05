resource "kubernetes_secret_v1" "vault_init_job" {
  metadata {
    name      = "vault-init-job"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }
  #type = "kubernetes.io/service-account-token"
}
resource "kubernetes_service_account_v1" "vault_init_job" {
  metadata {
    name      = "vault-init-job"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }
  secret {
    name = kubernetes_secret_v1.vault_init_job.metadata.0.name
  }
}

resource "kubernetes_role_binding" "vault_init_job_rb" {
  metadata {
    name      = "vault-init-job-rb"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_init_job.metadata.0.name
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
}

resource "kubernetes_config_map" "vault_init_script" {
  metadata {
    name      = "vault-init-script"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  data = {
    "vault-init.sh" = "${file("${path.module}/templates/vault-init.sh")}"
  }
}

resource "kubernetes_job" "vault_init" {
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
  metadata {
    name      = "vault-init"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }

  spec {
    template {
      metadata {}

      spec {
        volume {
          name = "script"

          config_map {
            name         = kubernetes_config_map.vault_init_script.metadata.0.name
            default_mode = "0777"
          }
        }

        container {
          name    = "vault-init"
          image   = "redislabs/rcp-kubectl:ca97cb1a3f347858453118d5eac77241"
          command = ["/script/vault-init.sh"]

          volume_mount {
            name       = "script"
            mount_path = "/script"
          }
        }

        restart_policy       = "Never"
        service_account_name = kubernetes_service_account_v1.vault_init_job.metadata.0.name
      }
    }
  }
  depends_on = [
    helm_release.vault
  ]
}
data "kubernetes_secret" "vault_creds" {
  metadata {
    name      = "vault-creds"
    namespace = kubernetes_namespace.vault.metadata.0.name
  }
  depends_on = [
    kubernetes_job.vault_init
  ]
}
