#!/bin/bash


. ./env

cardano-cli transaction witness \
--signing-key-file ${KEYS_PATH}/payment-0.skey \
--tx-body-file tx.raw \
--out-file payment-0.witness \
${CARDANO_NET_PREFIX}

cardano-cli transaction witness \
--signing-key-file ${KEYS_PATH}/payment-1.skey \
--tx-body-file tx.raw \
--out-file payment-1.witness \
${CARDANO_NET_PREFIX}

cardano-cli transaction witness \
--signing-key-file ${KEYS_PATH}/payment-2.skey \
--tx-body-file tx.raw \
--out-file payment-2.witness \
${CARDANO_NET_PREFIX}


cardano-cli transaction assemble \
--tx-body-file tx.raw \
--witness-file payment-0.witness \
--witness-file payment-1.witness \
--witness-file payment-2.witness \
--out-file tx.signed
