#!/bin/bash


. ./env

ADDRESS=$(cat ${ADDRESSES_PATH}/script.addr)
DSTADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)


TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${ADDRESS} | tail -n +3 | sort -k3nr | tail -n 1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
TXIN=${UTXO}#${ID}


# for a transaction signed by the owner
cardano-cli transaction build \
${CARDANO_NET_PREFIX} \
--babbage-era \
--tx-in ${TXIN} \
--change-address ${DSTADDRESS} \
--tx-in-script-file ${POLICY_PATH}/policy.script \
--out-file tx.raw

# for a transaction witnessed by 2 guardians
#cardano-cli transaction build \
#${CARDANO_NET_PREFIX} \
#--babbage-era \
#--tx-in ${TXIN} \
#--change-address ${DSTADDRESS} \
#--tx-in-script-file ${POLICY_PATH}/policy.script \
#--witness-override 2 \
#--out-file tx.raw \
#--invalid-before ${SLOT}
