# CMDK Genesis Kits

![drop-case](drop-case.jpg)

The CMDK Genesis Kit tokens are extended from the [ERC404](https://github.com/Pandora-Labs-Org/erc404) implementation.

* CMDKGenesisKit
    * The ERC404 token
* SupportersRewards
    * The base contract to burn MODA or EMT
* StakingRewards
    * The contract where the CMDKGenesisKit tokens are staked

Burn Cost is adjusted after each burn using the linear equation with the gradient calculated by the amount of cmdk kits allocated multiplied by the step amount.

Code style follows [Natspec](https://docs.soliditylang.org/en/latest/style-guide.html)

## Usage

### Build

```shell
$ npm i
```

### Test

[![test](https://github.com/DROPcmdk/cmdk-genesis/actions/workflows/test.yml/badge.svg)](https://github.com/DROPcmdk/cmdk-genesis/actions/workflows/test.yml)

```shell
$ npm test
```

#### With verbose logging

```shell
$ npm run test:logs
```

### Security Scans

[![Slither Analysis](https://github.com/DROPcmdk/cmdk-genesis-kit/actions/workflows/slither.yml/badge.svg)](https://github.com/DROPcmdk/cmdk-genesis-kit/actions/workflows/slither.yml)

Security scanning is done via the Slither gitaction. Vulnerabilities can be viewed [here](https://github.com/DROPcmdk/cmdk-genesis-kit/security/code-scanning).


### Deployment

Copy over env var file

```shell
$ cp .env.example .env
```

Load the variables in the .env file

```shell
$ source .env
```


#### Deploy CMDK Token

```shell
$ npm run deploy:cmdk:[mainnet or testnet]
```

#### Deploy Support Rewards for MODA

```shell
$ npm run deploy:modaRewards:[mainnet or testnet]
```

#### Deploy Support Rewards for EMT

```shell
$ npm run deploy:emtRewards:[mainnet or testnet]
```
