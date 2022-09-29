#!/bin/bash


. ./env

KEYHASH0=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-0.vkey)
KEYHASH1=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-1.vkey)
KEYHASH2=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-2.vkey)
KEYHASH3=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-3.vkey)


if [ ! -f ${POLICY_PATH}/policy.script ] ; then
cat << EOF >${POLICY_PATH}/policy.script
{
  "type": "any",
  "scripts":
  [
    {
      "type": "sig",
      "keyHash": "${KEYHASH0}"
    },
    {
      "type": "all",
      "scripts":
      [
        {
          "type": "after",
          "slot": ${SLOT}
        },
        {
          "type": "atLeast",
          "required": 2,
          "scripts":
          [
            {
              "type": "sig",
              "keyHash": "${KEYHASH1}"
            },
            {
              "type": "sig",
              "keyHash": "${KEYHASH2}"
            },
            {
              "type": "sig",
              "keyHash": "${KEYHASH3}"
            }
          ]
        }
      ]
    }
  ]
}
EOF
fi
