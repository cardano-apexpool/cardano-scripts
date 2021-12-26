#!/bin/bash


. ./env

cardano-cli transaction submit \
--tx-file tx.signed \
${CARDANO_NET_PREFIX}
