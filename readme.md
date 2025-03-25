This repository contains a Sui contract mocking Cetus swap interface as a showcase for Sui contract called by ZetaChain.

## Usage

### Deploy

Launch the localnet from https://github.com/zeta-chain/localnet

```
npx hardhat localnet --skip solana
```

The gateway package ID and object ID must be saved for later:

```
┌─────────────────┬────────────────────────────────────────────────────────────────────────────────┐
│     (index)     │                                     Values                                     │
├─────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ gatewayModuleID │      '0xbb671c52b335b8c5c315b58c23b3a17edab20da0a6bc6fad0ec8ba972b362850'      │
│ gatewayObjectId │      '0x75b252a25750a0f2e56c8bf6fb4dfd721d3ba7415599e8362ef616ed4f69115c'      │
```

Deploy the package, from this repo

```
sui move build
sui client publish
```

The following object must be saved, object IDs can be found in the logs:
- treasuryCap
- pool
- config
- partner
- clock

### Initialize Cetusmock

We deposit tokenB in the pool to simulate liquidity (tokenB are withdrawn when swap is called with tokenA)

Mint TokenB:

```
export PACKAGE="0xb112f370bc8e3ba6e45ad1a954660099fc3e6de2a203df9d26e11aa0d870f635"
export TREASURY="0x9416876796811bee4dfc45be26ff93ded0c50096dc96aadb034ec5bbd9cbe35a"
export POOL="0xbab1a2d90ea585eab574932e1b3467ff1d5d3f2aee55fed304f963ca2b9209eb"
export RECIPIENT="0x6ee1f834682e970077b913f43c398cfcd44bb049d39ced6be86eae0a7fce5740"

sui client call \
  --package "$PACKAGE" \
  --module token \
  --function mint \
  --args "$TREASURY" 1000000 "$RECIPIENT"
```

The owned bag of tokenB can be found by querying the objects of the owner:

```
sui client objects
```

Deposit TokenB into the pool

```
export TOKEN="0x210bc1199ce7395b9aac5fcd966eef7bb461a150c833649545763b8a4b0846af"

sui client call \
  --package "$PACKAGE" \
  --module cetusmock \
  --function deposit \
  --type-args "0x2::sui::SUI" "$PACKAGE::token::TOKEN" \
  --args "$POOL" "$TOKEN"
```

### Making the call from ZetaChain

Find a SUI bag to deposit:

```
sui client gas
```

Deposit SUI from Sui to ZetaChain:

```
export GATEWAY_PACKAGE="0xbb671c52b335b8c5c315b58c23b3a17edab20da0a6bc6fad0ec8ba972b362850"
export GATEWAY_OBJECT="0x75b252a25750a0f2e56c8bf6fb4dfd721d3ba7415599e8362ef616ed4f69115c"
export COIN="0x4a8dcd9b9e84f391a65764552db12960d3ea5a28eb96c057362c1975f400ff2a"
export ETH_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

sui client call \
  --package "$GATEWAY_PACKAGE" \
  --module gateway \
  --function deposit \
  --type-args 0x2::sui::SUI \
  --args "$GATEWAY_OBJECT" "$COIN" "$ETH_ADDRESS"
```

Approve SUI ZRC20 to be withdrawn from Zeta:

```
cast send 0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891 "approve(address,uint256)" 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 1000000000000000000000000 --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Now to make the `withdrawAndCall`, the arguments for the target contract must be encoded. A script in https://github.com/zeta-chain/example-contracts allow to encode this argument (currently in branch `sui-encode-call`)

Move to the directory:

```
cd examples/call
```

Create the encoded payload:

Note: `MESSAGE` contains the destination address to receive the swapped tokens.

```
export TOKEN_TYPE="0xb112f370bc8e3ba6e45ad1a954660099fc3e6de2a203df9d26e11aa0d870f635::token::TOKEN"
export CONFIG="0x57dd7b5841300199ac87b420ddeb48229523e76af423b4fce37da0cb78604408"
export POOL="0xbab1a2d90ea585eab574932e1b3467ff1d5d3f2aee55fed304f963ca2b9209eb"
export PARTNER="0xee6f1f44d24a8bf7268d82425d6e7bd8b9c48d11b2119b20756ee150c8e24ac3"
export CLOCK="0x039ce62b538a0d0fca21c3c3a5b99adf519d55e534c536568fbcca40ee61fb7e"
export MESSAGE="0x3573924024f4a7ff8e6755cb2d9fdeef69bdb65329f081d21b0b6ab37a265d06"

npx ts-node sui/setup/encodeCallArgs.ts \
  "$TOKEN_TYPE" \
  "$CONFIG,$POOL,$PARTNER,$CLOCK" \
  "$MESSAGE"
```

Finally `withdrawAndCall` can be called:

```
cast send 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "withdrawAndCall(bytes,uint256,address,bytes,(uint256,bool),(address,bool,address,bytes,uint256))" \
  "0xb112f370bc8e3ba6e45ad1a954660099fc3e6de2a203df9d26e11aa0d870f635" \
  "1000000" \
  "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891" \
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000503078623131326633373062633865336261366534356164316139353436363030393966633365366465326132303364663964323665313161613064383730663633353a3a746f6b656e3a3a544f4b454e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000457dd7b5841300199ac87b420ddeb48229523e76af423b4fce37da0cb78604408bab1a2d90ea585eab574932e1b3467ff1d5d3f2aee55fed304f963ca2b9209ebee6f1f44d24a8bf7268d82425d6e7bd8b9c48d11b2119b20756ee150c8e24ac3039ce62b538a0d0fca21c3c3a5b99adf519d55e534c536568fbcca40ee61fb7e00000000000000000000000000000000000000000000000000000000000000203573924024f4a7ff8e6755cb2d9fdeef69bdb65329f081d21b0b6ab37a265d06" \
  "(10000,false)" \
  "(0xB0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,true,0xC0b86991c6218b36c1d19D4a2e9Eb0cE3606eB49,0xdeadbeef,50000)" \
  --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  
```

The user can check the effects by checking the change in the pool balances.