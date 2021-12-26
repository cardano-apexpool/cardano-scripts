#!/bin/bash


. ./env

cardano-cli address build \
--payment-script-file ${POLICY_PATH}/policy.script \
${CARDANO_NET_PREFIX} \
--out-file ${ADDRESSES_PATH}/script.addr

cardano-cli address build \
--payment-script-file ${POLICY_PATH}/policy.script \
--stake-verification-key-file ${KEYS_PATH}/stake.vkey \
${CARDANO_NET_PREFIX} \
--out-file ${ADDRESSES_PATH}/script-with-stake.addr

