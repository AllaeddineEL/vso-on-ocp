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

data "http" "cert_manager_openshift_routes" {
  url = "https://github.com/cert-manager/openshift-routes/releases/latest/download/cert-manager-openshift-routes.yaml"
}
data "kubectl_file_documents" "cert_manager_openshift_routes_docs" {
  content = data.http.cert_manager_openshift_routes.response_body
}
resource "kubectl_manifest" "cert_manager_openshift_routes" {
  for_each        = data.kubectl_file_documents.cert_manager_openshift_routes_docs.manifests
  validate_schema = false
  force_new       = true
  yaml_body       = each.value
  depends_on      = [kubectl_manifest.cluster_issuer, helm_release.cert_manager]
}
resource "kubernetes_annotations" "ocp_console" {
  api_version = "route.openshift.io/v1"
  kind        = "Route"
  metadata {
    name      = "console"
    namespace = "openshift-console"
  }
  annotations = {
    "cert-manager.io/issuer-kind" = "ClusterIssuer"
    "cert-manager.io/issuer-name" = "letsencrypt-prod"
  }
  depends_on = [kubectl_manifest.cert_manager_openshift_routes]
}

resource "kubernetes_annotations" "oauth" {
  api_version = "route.openshift.io/v1"
  kind        = "Route"
  metadata {
    name      = "oauth-openshift"
    namespace = "openshift-authentication"
  }
  annotations = {
    "cert-manager.io/issuer-kind" = "ClusterIssuer"
    "cert-manager.io/issuer-name" = "letsencrypt-prod"
  }
  depends_on = [kubectl_manifest.cert_manager_openshift_routes]
}

resource "kubectl_manifest" "console_route" {
  validate_schema = false
  force_new       = true
  yaml_body       = <<-EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: console
  name: console-custom
  namespace: openshift-console
spec:
  host: console-openshift-console.crc-vm.yqcbbqbbs7qx.instruqt.io
  port:
    targetPort: https
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: reencrypt
  to:
    kind: Service
    name: console
    weight: 100
  wildcardPolicy: None
EOF
}

resource "kubectl_manifest" "oauth_route" {
  validate_schema = false
  force_new       = true
  yaml_body       = <<-EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: oauth-openshift
  name: oauth-openshift
  namespace: openshift-authentication
spec:
  host: oauth-openshift.crc-vm.yqcbbqbbs7qx.instruqt.io
  port:
    targetPort: 6443
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: passthrough
  to:
    kind: Service
    name: oauth-openshift
    weight: 100
  wildcardPolicy: None
EOF
}
