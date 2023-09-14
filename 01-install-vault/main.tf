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
  version          = "0.25.0"
  create_namespace = false
  values = [
    templatefile("${path.module}/templates/vault/vault.yaml", { vault_fqdn = "vault.crc-vm.${var.sandbox_id}.instruqt.io" })
  ]
  depends_on = [kubectl_manifest.vault_certs]
}

resource "kubectl_manifest" "vault_network_policy" {
  validate_schema = false
  yaml_body       = <<-EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-vso-namespace
  namespace: vault
spec:
  podSelector:
    matchLabels: 
      app.kubernetes.io/name: vault    
  policyTypes:
  - Ingress 
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          projectName: vso
  EOF
}
