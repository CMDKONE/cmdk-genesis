# CMDK Genesis Kits

The CMDK Genesis Kit tokens are extended from the [DN404](https://github.com/vectorized/dn404.git) implementation.

Burning of EMT and MODA is done through the use of the SupporterRewards contract.
An instance per token is created. Rewards can be adjusted as needed.

Burn Cost is adjusted after each burn using the linear equation with the gradient calculated by the amount of cmdk kits allocated multiplied by the step amount.

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

#### With verbose logging

```shell
$ npm run test:logs
```

### Deployment


#### Deploy CMDK Token

```shell
$ npm run deploy:cmdk
```

#### Deploy Support Rewards for MODA

```shell
$ npm run deploy:modaRewards
```

#### Deploy Support Rewards for EMT

```shell
$ npm run deploy:emtRewards
```
