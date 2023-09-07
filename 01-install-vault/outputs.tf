# output "vault_root_token" {
#   value = nonsensitive(data.kubernetes_secret.vault_creds.data["vault_root_token"])
#   # sensitive = true
# }
# output "vault_unseal_key" {
#   value = nonsensitive(data.kubernetes_secret.vault_creds.data["vault_unseal_key"])
#   # sensitive = true
# }

output "vault_url" {
  value = "https://vault.crc-vm.${var.sandbox_id}.instruqt.io"
}
