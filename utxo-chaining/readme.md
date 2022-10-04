### UTXO chaining 

This is a feature in blockchains that use UTXO ledger model. Here chaining means that you can make transactions that depends on the output of another transaction
In this we are using ogmios.

The first step is to create transactions. Here we use cardano-cli and then serialize using bash script

```
#!/bin/bash



ADDRESS=$PREVIEW_ADDRESS

TRANS=$(cardano-cli query utxo $NET --address $ADDRESS | sort -k3n | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
TXIN=${UTXO}#${ID}


cardano-cli transaction build \
$NET \
--tx-in "c4a870726bc48056f172a37d412e84e5955878df9fb0a9927849c5b731a2aa03#0" \
--tx-in "c55959fdfd58ce3bb95bcba8b4249e249db729e285b707644188a46058d0e2ac#0" \
--tx-out ${ADDRESS}+15000000000 \
--change-address ${ADDRESS} \
--out-file tx4.raw

TX4=$(cardano-cli transaction txid --tx-body-file tx4.raw)

cardano-cli transaction sign \
--tx-body-file tx4.raw \
--signing-key-file payment.skey \
$NET \
--out-file tx4.signed

jq .cborHex tx4.signed  | xxd -r -p > tx4.signed.cbor


cardano-cli transaction build-raw \
--tx-in "f5307da70dcc8f2964c8d12c00a49e2b54f210ed66c6a6be9d59e4a657d72b06#0" \
--tx-in "${TX4}#0" \
--tx-out ${ADDRESS}+14000000000 \
--tx-out ${ADDRESS}+498286349 \
--fee 174213 \
--out-file tx5.raw

cardano-cli transaction sign \
--tx-body-file tx5.raw \
--signing-key-file payment.skey \
$NET \
--out-file tx5.signed

jq .cborHex tx5.signed  | xxd -r -p > tx5.signed.cbor

```

Next step is to use ogmios. https://ogmios.dev/getting-started/docker/





```

import json
import base64
import websocket
 

URL = '<ogmios_ip>:<ogmios_port>'

if __name__ == "__main__":
    #
    ws = websocket.create_connection(URL)
    #

    with open('tx4.signed.cbor', 'rb') as f:
        cbor_trans = f.read()
    trans = base64.b64encode(cbor_trans).decode()

    msg = '{"type": "jsonwsp/request", "version": "1.0", "servicename": "ogmios", "methodname": "SubmitTx", "args": {"submit": "%s"}}' % trans

    ws.send(msg)
    r = json.loads(ws.recv())
    if r['type'] == 'jsonwsp/response' and 'SubmitFail' in r['result']:
        print(r['type'])
        for item in r['result']['SubmitFail']:
            print(list(item.keys()))

    print(json.dumps(r, indent=2))

    with open('tx5.signed.cbor', 'rb') as f:
        cbor_trans = f.read()
    trans = base64.b64encode(cbor_trans).decode()

    msg = '{"type": "jsonwsp/request", "version": "1.0", "servicename": "ogmios", "methodname": "SubmitTx", "args": {"submit": "%s"}}' % trans

    ws.send(msg)
    r = json.loads(ws.recv())
    if r['type'] == 'jsonwsp/response' and 'SubmitFail' in r['result']:
        print(r['type'])
        for item in r['result']['SubmitFail']:
            print(list(item.keys()))

    print(json.dumps(r, indent=2))
 
 ```
 
 
 This is just a simple way to create utxo chaining. Please note that you should have IN connections for the cardano-node as it will have updated mempool or you should submit all transactions in same node
 
