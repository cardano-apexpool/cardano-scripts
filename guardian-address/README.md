***Guardian Address***
```
In some recent discussions, there was a general desire to have recovery of funds incase the primary owner forgets keys or is not in capacity to use it.

So the requirements are as follows
1) There is primary signature. This is the owner of this address
2) The owner can sign transactions and spend any time
3) The owner will decide on guardians. Typically this should be 3 guardians and atleast 2 should be necessary to recover
4) The guardians signature can be set with a timeout. So before the timeout guardians cannot use their keys. Only the primary owner is able to spend
5) If the primary owner wants to renew the timeout then it should be possible with same set of guardians but the timeout pushed to future
```


***Approach***
```
Usually smart contracts are used to create these kind of addresses. They are also called social wallets that provide a lot more capabilities. The idea here
is not to provide social wallet. Instead the goal is that primary owner does not have to worry about losing keys or incase of death/injury guardians can help.
Self custody is always the best. However many usecases do need guardians.

Instead of using smart contracts, we use native scripts. Cardano has native scripts which have some nice capability but are very easy to verify unlike smart contracts.
So the capabilities of native script we use are
1) Single signer
2) Script composing of another script
3) Slot configuation
4) m-of-n signature
```
Here is the sample file that helps generate a script address taking into consideration requirements 1 to 4 above

```json
{
  "type": "any",
  "scripts":
  [
    {
      "type": "sig",
      "keyHash": "Hash of Primary Key"
    },
    {
      "type": "all",
      "scripts":
      [
        {
          "type": "after",
          "slot": slot number
        },
        {
          "type": "atLeast",
          "required": 2,
          "scripts":
          [
            {
              "type": "sig",
              "keyHash": "guardian 1"
            },
            {
              "type": "sig",
              "keyHash": "guardian 2"
            },
            {
              "type": "sig",
              "keyHash": "guardian 3"
            }
          ]
        }
      ]
    }
  ]
}
```

What this script file says is 
1) Allow primary owner to spend any time
2) or after slot number x allow spending only if 2 of the 3 guardians sign

The scripts to generate and run are in this folder
