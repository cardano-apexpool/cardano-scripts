#!/bin/bash


. ./env

cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file wallet/stake.vkey \
    --stake-pool-id 5f5ed4eb2ba354ab2ad7c8859f3dacf93564637a105e80c8d8a7dc3c \
    --out-file deleg.cert

currentSlot=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
echo Current Slot: $currentSlot

cardano-cli query utxo \
    --address $(cat wallet/script.addr) \
    ${CARDANO_NET_PREFIX} > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}

cardano-cli transaction build \
${tx_in} \
--change-address $(cat wallet/script.addr) \
--tx-in-script-file ${POLICY_PATH}/policy.script \
--witness-override 4 \
--out-file tx.raw \
--certificate-file deleg.cert  \
${CARDANO_NET_PREFIX}
