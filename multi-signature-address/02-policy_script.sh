#!/bin/bash


. ./env

KEYHASH0=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-0.vkey)
KEYHASH1=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-1.vkey)
KEYHASH2=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-2.vkey)


if [ ! -f ${POLICY_PATH}/policy.script ] ; then
cat << EOF >${POLICY_PATH}/policy.script
{
  "type": "all",
  "scripts":
  [
    {
      "type": "sig",
      "keyHash": "${KEYHASH0}"
    },
    {
      "type": "sig",
      "keyHash": "${KEYHASH1}"
    },
    {
      "type": "sig",
      "keyHash": "${KEYHASH2}"
    }
  ]
}
EOF
fi
