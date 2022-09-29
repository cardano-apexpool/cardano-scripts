#!/bin/bash


. ./env

cardano-cli transaction sign \
--signing-key-file ${KEYS_PATH}/payment-0.skey \
--tx-body-file tx.raw \
--out-file tx.signed \
${CARDANO_NET_PREFIX}
