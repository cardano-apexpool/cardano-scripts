I heard a few times about multi-signature addresses on Cardano, but I never really saw an example using such an address. I found some documentation about this here, but I realized it is outdated and the commands are not working anymore as they are on this page. This is why I decided to write this post after doing some successful tests with multi-signature addresses.

But first, what is a multi-signature address? A multi-signature address is an address associated with multiple private keys, which can be in the possession of different persons, so that a transaction from that address can be performed only when all the private keys are used to sign the transaction.

I decided to create 3 private keys for my multi-signature address demo, and I did it on testnet, but it is the similar to mainnet. I am using Daedalus-testnet as my cardano node for my demo. I also created a Github repository with the files used in this demo, to be easier to create locally the files, in case someone wants to test this.

First thing I created was a file with a few environment variables that will be used by all the scripts. This also generates the folders required for the other scripts, in case they do not already exist, and the protocol parameters file, required by some of the commands. I called this file “env”:

    #!/bin/bash


    # for testnet
    CARDANO_NET="testnet"
    CARDANO_NET_PREFIX="--testnet-magic 1097911063"
    # for mainnet
    #CARDANO_NET="mainnet"
    #CARDANO_NET_PREFIX="--mainnet"
    #
    KEYS_PATH=./wallet
    ADDRESSES_PATH=./wallet
    FILES_PATH=./files
    POLICY_PATH=./policy
    PROTOCOL_PARAMETERS=${FILES_PATH}/protocol-parameters.json
    export CARDANO_NODE_SOCKET_PATH=~/.local/share/Daedalus/${CARDANO_NET}/cardano-node.socket

    if [ ! -d ${KEYS_PATH} ] ; then
      mkdir -p ${KEYS_PATH}
    fi

    if [ ! -d ${ADDRESSES_PATH} ] ; then
      mkdir -p ${ADDRESSES_PATH}
    fi

    if [ ! -d ${FILES_PATH} ] ; then
      mkdir -p ${FILES_PATH}
    fi

    if [ ! -d ${POLICY_PATH} ] ; then
      mkdir -p ${POLICY_PATH}
    fi

    if [ ! -f ${PROTOCOL_PARAMETERS} ] ; then
      cardano-cli query protocol-parameters --out-file  ${PROTOCOL_PARAMETERS} ${CARDANO_NET_PREFIX}
    fi

The first script will generate the 3 pairs of private and public keys used to control the multi-signature address. Because it is also possible to associate the address with a staking key and delegate it to a stake pool, I also created a stake keys pair and I will also generate later the address including the stake address. This is the first script, called “01-keys.sh”:

    #!/bin/bash


    . ./env

    for i in {0..2}
    do
      if [ -f "${KEYS_PATH}/payment-${i}.skey" ] ; then
        echo "Key already exists!"
      else
        cardano-cli address key-gen --verification-key-file ${KEYS_PATH}/payment-${i}.vkey --signing-key-file ${KEYS_PATH}/payment-${i}.skey
      fi
    done

    cardano-cli stake-address key-gen --verification-key-file ${KEYS_PATH}/stake.vkey --signing-key-file ${KEYS_PATH}/stake.skey

Executing this script with “. 01-keys.sh” will create the folders, will generate the 3 payment key pairs and the stake key pair in the “wallet” folder, and will also generate the protocol-parameters.json file in the “files” folder.

The next step is generating the policy script that will require all 3 payment keys to be used when doing a transaction. I called this script “02-policy_script.sh”:

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

Executing this (with “. 02-policy_script.sh”) will generate the policy/policy.script file.

The next step is to compute the multi-signature payment address from this policy script, which includes the hashes of the 3 payment verification keys generated in the first step. I computer the address both with and without the including the stake address. I called this script “03-script-addr.sh”:

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

Don’t forget to execute this script: “. 03-script-addr.sh”. After that, you can send some testnet funds (tADA) from your wallet to this address (found in wallet/script.addr). You can also request 1000 tADA from the testnet faucet. I requested them from the faucet right now. You can check if you received the funds like this:

    $ cardano-cli query utxo ${CARDANO_NET_PREFIX} --address $(<wallet/script.addr)
                               TxHash                                 TxIx        Amount 
    --------------------------------------------------------------------------------------
    14d8610f16738b41c3d1f...224e1e792ceb1c9db279#0     0        1000000000 lovelace + TxOutDatumNone 

As you can see, the 1000 tADA are there in my example (I censored a few characters from the transaction id).

The next step is to actually test sending the tADA from this address to a different address with a transaction. I created a file “wallet/dev_wallet.addr” where I wrote the address where I want to send the funds. The script used to create this transaction is “04-transaction.sh”:

    #!/bin/bash


    . ./env

    ADDRESS=$(cat ${ADDRESSES_PATH}/script.addr)
    DSTADDRESS=$(cat ${ADDRESSES_PATH}/dev_wallet.addr)

    TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${ADDRESS} | tail -n1)
    UTXO=$(echo ${TRANS} | awk '{print $1}')
    ID=$(echo ${TRANS} | awk '{print $2}')
    TXIN=${UTXO}#${ID}

    cardano-cli transaction build \
    --tx-in ${TXIN} \
    --change-address ${DSTADDRESS} \
    --tx-in-script-file ${POLICY_PATH}/policy.script \
    --witness-override 3 \
    --out-file tx.raw \
    ${CARDANO_NET_PREFIX}

I created the transaction with the newer “cardano-cli transaction build” command, because this will also automatically compute the minimum required fees for the transaction, and we skip 2 steps (calculating the fee and generating the transaction with the correct fees) compared to using the “cardano-cli transaction build-raw” method. Also notice the “–tx-in-script-file” parameter, which is very important when using multi-signature addresses, and the “–witness-override 3” used to calculate the correct transaction fees, because we are using 3 private keys to sign the transaction later.

Executing this script (“. 04-transaction.sh”) will generate the “tx.raw” raw transaction file, and will also inform us about the fees for the transaction: “Estimated transaction fee: Lovelace 178657”.

We can examine the transaction file using this command:

    $ cardano-cli transaction view --tx-body-file tx.raw 
    auxiliary scripts: null
    certificates: null
    era: Alonzo
    fee: 178657 Lovelace
    inputs:
    - 14d8610f16738b41.....e792ceb1c9db279#0
    mint: null
    outputs:
    - address: addr_test1............yy33
      address era: Shelley
      amount:
        lovelace: 999821343
      datum: null
      network: Testnet
      payment credential:
        key hash: e98ef513e28e93b909183292cd27956ddd9939ec6afcbee8694386ab
      stake reference:
        key hash: 10e893f172924ccbe98d3629b9dce63b26664c1c567af0b31327e596
    update proposal: null
    validity range:
      lower bound: null
      upper bound: null
    withdrawals: null

I censored the characters in the input UTxO and in the destination address in the output above.

Now the transaction needs to be signed. This can be done using “cardano-cli transaction sign” (the “05-sign.sh” script file), but this is only possible when one person has all the private keys, and the whole idea of multi-signature addresses is that the private keys are distributed to different persons. This is why we need to “witness” the transaction with all the different signature (private) payment keys, and assemble the signed transaction from all of them. This is done in the script “05-witness.sh”:

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

If you test both ways and compare the results, you will see that the “tx.signed” generated files are identical. Don’t forget to execute the script: “. 05-witness.sh”. The file “tx.signed” will be generated, and the last step of the demo is to submit the signed transaction to a cardano node (using the “06-submit.sh” script):

    #!/bin/bash


    . ./env

    cardano-cli transaction submit \
    --tx-file tx.signed \
    ${CARDANO_NET_PREFIX}

Execute the script:

    $ . 06-submit.sh
    Transaction successfully submitted. 

After some seconds (next block being minted), the funds should be at the destination address (I censored a few characters from the transaction id):

    $ cardano-cli query utxo ${CARDANO_NET_PREFIX} --address $(<wallet/dev_wallet.addr)
                                TxHash                                 TxIx        Amount
    --------------------------------------------------------------------------------------
    8902f1b5e18cc494a36f8...ac5653df5cfea3b550ce     0        999821343 lovelace + TxOutDatumNone 

Subtracting the transaction fee from the 1000 tADA, we will see that the 999816899 are exactly the amount expected to be at the destination address:

    $ expr 1000000000 - 178657
    999821343 

Also interrogating the script address will show that the 1000 tADA are no longer there:

    $ cardano-cli query utxo ${CARDANO_NET_PREFIX} --address $(<wallet/script.addr)
                                TxHash                                 TxIx        Amount
    --------------------------------------------------------------------------------------

And this concludes my demo with multi-signature addresses on Cardano.

I also tested the scripts with funds being sent to the script address that includes the stake address (“wallet/script-with-stake.addr”), in case you were wondering. This type of address can be used to delegate the funds at a multi-signature address to a stake pool.


Now to delegate this multisig wallet 

You need to first register the stake. This can be done by running following 3 scripts

```
   . ./07-deleg.sh
   . ./05-sign.sh
   . ./06-submit.sh
```   
   
 Once this is done, you now need to delegate the stake. In this example the script address is delegated to Apex pool
 
    . ./deleg-08.sh
    . ./07-sign-delegation.sh
    . ./06-submit.sh
    
