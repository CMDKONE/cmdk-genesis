# CMDK Genesis Kits

The CMDK Genesis Kit tokens are extended from the DN404 implementation.

Burning and Staking of EMT and MODA is done through the use of the SupporterRewards contract.
An instance of each is created per token. Rewards can be allocated and adjusted as needed.

These contracts will be first deployed on Ethereum and then bridged using Layer Zero and Arbitrum Bridge.

Code style follows [Natspec](https://docs.soliditylang.org/en/latest/style-guide.html)

## Usage

### Build

```shell
$ npm i
```

### Test

```shell
$ npm test
```

### Deploy Token

```shell
$ npm run deploy:token
```
