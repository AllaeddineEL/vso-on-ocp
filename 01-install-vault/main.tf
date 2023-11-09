resource "kubectl_manifest" "vault_certs" {
  validate_schema = false
  yaml_body       = <<-EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vault-certs
  namespace: vault
spec:
  secretName: vault-certs
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: "vault.crc-vm.${var.sandbox_id}.instruqt.io"
  dnsNames:
    - "vault.crc-vm.${var.sandbox_id}.instruqt.io"
    - "localhost"
  ipAddresses:
    - 127.0.0.1  
  EOF
  depends_on      = [kubectl_manifest.cluster_issuer]
}
resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "vault"
  version          = "0.26.1"
  create_namespace = false
  values = [
    templatefile("${path.module}/templates/vault/vault.yaml", { vault_fqdn = "vault.crc-vm.${var.sandbox_id}.instruqt.io" })
  ]
  depends_on = [kubectl_manifest.vault_certs,
    kubectl_manifest.cert_manager_openshift_routes
  ]
}

resource "kubectl_manifest" "vault_network_policy" {
  validate_schema = false
  yaml_body       = <<-EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-from-vso-namespace
  namespace: vault
spec:
  podSelector: {}
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: vso
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: dev-backend
  policyTypes:
  - Ingress
EOF
}
