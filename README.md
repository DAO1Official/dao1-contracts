# Smart contracts for DAO1

DAO1 Ethereum contracts

![Solidity](https://img.shields.io/badge/solidity-v0.8-green)
![License](https://img.shields.io/github/license/OnGridSystems/dao1_contracts)
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2FOnGridSystems%2Fdao1_contracts%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/OnGridSystems/dao1_contracts/goto?ref=master)

## Deployments

Matic mainnet: 

 - MaticDAO1FarmingQuickswap address ["0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731"](https://polygonscan.com/address/0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731)
 - MaticDAO1FarmingQuickswap2 address ["0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43"](https://polygonscan.com/address/0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43)

Ethereum mainnet:

 - DAO1DaiVault address ["0x66aaEFd332a3148f8D7892a6cC67b5228dA88F9A"](https://etherscan.io/address/0x66aaEFd332a3148f8D7892a6cC67b5228dA88F9A)
 - DAO1FarmingSafeswap address ["0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731"](https://etherscan.io/address/0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731)
 - DAO1FarmingUniswap address ["0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43"](https://etherscan.io/address/0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43)
 - YfDaiFarmingUniswap address ["0xCBc033a017B1F6e4b359D2ABeD0C0e9623bb7D5A"](https://etherscan.io/address/0xCBc033a017B1F6e4b359D2ABeD0C0e9623bb7D5A)

Install node packages (hardhat)

`yarn install`
 
## Testing deploy (rinkeby, matic)

Create local environments

```
unset DAO1Address
export MNEMONIC='<your MNEMONIC phrase>'
export INFURA_API_KEY=<your API key>
```

Run deploy

```
npx hardhat --network rinkeby deploy
npx hardhat --network rinkeby etherscan-verify --solc-input --api-key <Etherscan_API_Key>

npx hardhat --network mumbai deploy
npx hardhat --network mumbai etherscan-verify --solc-input --api-key <Etherscan_API_Key>
```

## Local-fork deploy (mainnet, matic)

Create local environments for mainnet

```
export DAO1Address=0xce3f6f6672616c39d8b6858f8dac9902eca42c84
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
export INFURA_API_KEY=<your API key>
export MAINNET_UPSTREAM=https://mainnet.infura.io/v3/${INFURA_API_KEY}
```

Run ganache-cli docker container for deploy mainnet-fork

```
docker run --detach --rm --publish 8545:8545 trufflesuite/ganache-cli:latest --fork ${MAINNET_UPSTREAM} --chainId 1
```

Run deploy mainnet-fork

```
npx hardhat --network mainnet-fork deploy --tags FixedStaking30Days,FixedStaking60Days,FixedStaking90Days
```

Stop ganache-cli docker container

```
docker ps
docker stop <container_id>
```

Create local environments for matic-fork

```
export DAO1Address=0x3c5D1617C30BA71972adD4b0C9A6B9848f2afeeD
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
export MATIC_UPSTREAM=https://matic-mainnet.chainstacklabs.com
```
Run ganache-cli docker container for deploy matic-fork

```
docker run --detach  --rm --publish 8545:8545 trufflesuite/ganache-cli:latest --mnemonic "${MNEMONIC}" --fork ${MATIC_UPSTREAM} --chainId 137
```

Run deploy matic-fork

```
npx hardhat --network matic-fork deploy --tags FixedStaking30Days,FixedStaking60Days,FixedStaking90Days
```

Stop ganache-cli docker container

```
docker ps
docker stop <container_id>
```

## Production deploy (mainnet, matic)

Create local environments for mainnet

```
export DAO1Address=0xce3f6f6672616c39d8b6858f8dac9902eca42c84
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
export INFURA_API_KEY=<your API key>
```

Run deploy mainnet

```
npx hardhat --network mainnet deploy
npx hardhat --network mainnet etherscan-verify --solc-input --api-key <Etherscan_API_Key>
```

Create local environments for matic

```
export DAO1Address=0x3c5D1617C30BA71972adD4b0C9A6B9848f2afeeD
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
```

Run deploy matic

```
npx hardhat --network matic deploy
npx hardhat --network matic etherscan-verify --solc-input --api-key <Etherscan_API_Key>
```