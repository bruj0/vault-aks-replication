#!/bin/bash -x
VAULT_TOKEN_A="...."
VAULT_TOKEN_B="...."
LB_IP_A="..."
LB_IP_B="..."
#vault-cluster-A
vault1="env VAULT_TOKEN=${VAULT_TOKEN_A} VAULT_ADDR=http://127.0.0.1:8200 vault"
vault1_cluster="https://${LB_IP_A}:8201"
vault1_api="http://${LB_IP_A}:8200"


#vault-cluster-B
vault2="env VAULT_TOKEN=${VAULT_TOKEN_A}  VAULT_ADDR=http://127.0.0.1:9200 vault"
vault2_cluster="https://${LB_IP_B}:8201"
vault2_api="https://$LB_IP_B}:8200"

#Starting Performance Replication from Vault1 to Vault2
#Disable perf replication on primary
${vault1} write -f sys/replication/performance/primary/disable
sleep 3 
#Enable Performance replication on Primary
${vault1} write -f sys/replication/performance/primary/enable primary_cluster_addr=${vault1_cluster}

#Get the Secondary public key for Perf replication
PR_secondary_public_key=$( ${vault2} write -f -field=secondary_public_key sys/replication/performance/secondary/generate-public-key )
#Generate the Secondary bootstrap token on Primary using the public key
bootstrap=$( ${vault1} write -field=token sys/replication/performance/primary/secondary-token id=asdf secondary_public_key="${PR_secondary_public_key}" )
#Enable replication on Secondary using the bootstrap token
${vault2} write sys/replication/performance/secondary/enable token="$bootstrap" primary_api_addr=${vault1_api}
#Starting Disaster Recovery replication from Vault2 to Vault3
#sleep 3
#Enable DR replication
#${vault2} write -f sys/replication/dr/primary/enable
#sleep 1
#Get the Secondary public key for DR replication
#DR_secondary_public_key=$(${vault3} write -f -field=secondary_public_key sys/replication/dr/secondary/generate-public-key )
#Generate the DR Secondary bootstrap token using the DR secondary public key
#DR_bootstrap=$( ${vault2} write -field=token sys/replication/dr/primary/secondary-token id=vault3 secondary_public_key="$DR_secondary_public_key")
#Enable DR replicaton on Secondary(Vault2) using the bootstrap token
#${vault3} write sys/replication/dr/secondary/enable token="$DR_bootstrap"
