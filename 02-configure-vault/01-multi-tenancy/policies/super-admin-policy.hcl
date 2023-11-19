# * (glob) character matches any prefixes in the path and can only be used at the end
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}