#!/bin/bash

curl -OL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
mv jq-linux64 /usr/local/bin/jq

wait_for_running() {
POD_NAME=$1

check() {
    kubectl get pods $1 -n vault -o json | \
        jq -r 'select(
            .status.phase == "Running" and
            ([ .status.conditions[] | select(.type == "Ready" and .status == "False") ] | length) == 1
        ) | .metadata.namespace + "/" + .metadata.name'
}

for i in $(seq 60); do
    if [ -n "$(check ${POD_NAME})" ]; then
        echo "${POD_NAME} is Running."
        sleep 5
        return
    fi

    echo "Waiting for ${POD_NAME} to become Running..."
    sleep 2
done

echo "${POD_NAME} never became Running."
return 1
}

wait_for_running vault-0

INIT_VAULT=$(kubectl exec vault-0 -c vault -n vault -- vault operator init -key-shares 1 -key-threshold 1 -format=json)

VAULT_UNSEAL_KEY=$(echo $INIT_VAULT | jq -r ".unseal_keys_b64 | .[]")
VAULT_ROOT_TOKEN=$(echo $INIT_VAULT | jq -r ".root_token")

kubectl exec vault-0 -c vault -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl exec vault-0 -c fluentd -n vault -- curl -s --request POST --header "X-Vault-Token: $VAULT_ROOT_TOKEN" --data '{"type": "file", "options": { "file_path": "/vault/logs/vault-audit.log" }}' http://127.0.0.1:8200/v1/sys/audit/vault-audit

kubectl create secret generic vault-creds -n vault \
--from-literal=vault_unseal_key=$VAULT_UNSEAL_KEY \
--from-literal=vault_root_token=$VAULT_ROOT_TOKEN