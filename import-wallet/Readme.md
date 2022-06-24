# In this method we create address using mnemonic.

The first step is to Create a 15-word or 24-word length shelley compatible mnemonic. You can create it in wallet like nami or even commandline. Choosing single address mode in wallets like typhoon,nami (is always single address) is beneficial


```
### machine connected to internet
wget https://github.com/input-output-hk/cardano-wallet/releases/download/v2022-05-27/cardano-wallet-v2022-05-27-linux64.tar.gz

### Copy this to air-gapped machine
tar -xvf cardano-wallet-v2022-05-27-linux64.tar.gz
export PATH="$(pwd)/cardano-wallet-v2022-05-27-linux64:$PATH"

```

### Air-gapped machine is a must have if you are using this on mainnet.

```
### Air-gapped machine. Use this if you want to generate. If you already generated with wallet like nami you can ignore this step

### If you use this method. Ensure to write down the mnemonic so that you can later import in wallet like nami. Choose single address mode

cardano-wallet recovery-phrase generate
```

Next use the cript file and mnemonic to generate address

```
###
### On air-gapped offline machine,
###
./extractPoolStakingKeys.sh extractedPoolKeys/ < mnemonic words >

```

All the keys are generated in the extractedPoolKeys folder. The base.addr is the address to be used. Please note .skey files are secret keys and they should never leave air-gapped machine

If you want to understand the details then you can  refer to this [wallet](https://armada-alliance.gitbook.io/ai-blockchain-edu/wallets)

[![Watch the video](https://img.youtube.com/vi/XKs-skBubXs/maxresdefault.jpg)]("https://www.youtube.com/watch?v=XKs-skBubXs")


