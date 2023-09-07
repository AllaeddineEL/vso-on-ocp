resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
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
}
resource "time_sleep" "wait" {
  create_duration = "60s"

  depends_on = [helm_release.cert_manager]
}

# resource "kubernetes_manifest" "cluster_issuer" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "ClusterIssuer"
#     "metadata" = {
#       "name" = "letsencrypt-prod"
#       # "namespace" = "${kubernetes_namespace.cert_manager.metadata.0.name}"
#     }
#     "spec" = {
#       "acme" = {
#         "email" = "nobody@hashicorp.com"
#         "privateKeySecretRef" = {
#           "name" = "letsencrypt-prod"
#         }
#         "server" = "https://acme-v02.api.letsencrypt.org/directory"
#         "solvers" = [
#           {
#             "http01" = {
#               "ingress" = {
#                 "class" = "openshift-default"
#               }
#             }
#           },
#         ]
#       }
#     }
#   }
#   wait {
#     rollout = true
#   }
#   depends_on = [time_sleep.wait, helm_release.cert_manager]
# }



resource "kubectl_manifest" "cluster_issuer" {
  validate_schema = false
  force_new       = true
  yaml_body       = <<-EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: ${kubernetes_namespace.cert_manager.metadata.0.name}
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: nobody@hashicorp.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: openshift-default
  EOF
  depends_on      = [time_sleep.wait, helm_release.cert_manager]
}