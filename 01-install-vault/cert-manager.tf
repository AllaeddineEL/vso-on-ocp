resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
  depends_on = [
    google_container_cluster.demo,
    google_container_node_pool.general
  ]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata.0.name
  create_namespace = false
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "1.11.0"
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [
    google_container_cluster.demo,
    google_container_node_pool.general,
    kubernetes_namespace.cert_manager
  ]
}
resource "time_sleep" "wait" {
  create_duration = "60s"

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = "letsencrypt-prod"
      "namespace" = "cert-manager"
    }
    "spec" = {
      "acme" = {
        "email" = "nobody@hashicorp.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = null
            "ingress" = {
              "class" = "openshift-default"
            }
          },
        ]
      }
    }
  }
}

# resource "kubectl_manifest" "cluster_issuer" {
#   validate_schema = false
#   yaml_body       = templatefile("${path.module}/templates/cert-manager/clusterissuer.yaml", { proj_id = var.project_id, domain_name = "${trimsuffix(data.google_dns_managed_zone.doormat_dns_zone.dns_name, ".")}" })
#   depends_on      = [time_sleep.wait]
# }

# resource "kubectl_manifest" "wildcard_certifcate" {
#   validate_schema = false
#   yaml_body       = templatefile("${path.module}/templates/cert-manager/certificate.yaml", { domain_name = "${trimsuffix(data.google_dns_managed_zone.doormat_dns_zone.dns_name, ".")}" })
#   depends_on      = [kubectl_manifest.cluster_issuer]
# }
# resource "kubernetes_manifest" "cluster_issuer" {
#   manifest   = yamldecode(templatefile("${path.module}/templates/clusterissuer.yaml", { proj_id = var.project_id, domain_name = "*.${trimsuffix(data.google_dns_managed_zone.doormat_dns_zone.dns_name, ".")}" }))
#   depends_on = [helm_release.cert_manager, time_sleep.wait]
# }
