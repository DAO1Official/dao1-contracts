# Smart contracts for DAO1

DAO1 Ethereum contracts

![Solidity](https://img.shields.io/badge/solidity-v0.8-green)
![License](https://img.shields.io/github/license/OnGridSystems/dao1_contracts)
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2FOnGridSystems%2Fdao1_contracts%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/OnGridSystems/dao1_contracts/goto?ref=master)

## Deployments

Matic mainnet: 

 - MaticDAO1FarmingQuickswap address ["0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731"](https://polygonscan.com/address/0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731)
 - MaticDAO1FarmingQuickswap2 address ["0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43"](https://polygonscan.com/address/0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43)
 - FixedStaking30Days address ["0xff6D784D5938CB3980Dce79BbAcEc53987D527d8"](https://polygonscan.com/address/0xff6D784D5938CB3980Dce79BbAcEc53987D527d8)
 - FixedStaking60Days address ["0x63aE7Ad4BC155561442207bB4a89a3FD697068D1"](https://polygonscan.com/address/0x63aE7Ad4BC155561442207bB4a89a3FD697068D1)
 - FixedStaking90Days address ["0xa295338aB1a4A648D3578Da6940acfdEEFFD9B6F"](https://polygonscan.com/address/0xa295338aB1a4A648D3578Da6940acfdEEFFD9B6F)

Ethereum mainnet:

 - DAO1DaiVault address ["0x66aaEFd332a3148f8D7892a6cC67b5228dA88F9A"](https://etherscan.io/address/0x66aaEFd332a3148f8D7892a6cC67b5228dA88F9A)
 - DAO1FarmingSafeswap address ["0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731"](https://etherscan.io/address/0xdAed3a8DA5429706710f14AFEaCd12a33d5e6731)
 - DAO1FarmingUniswap address ["0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43"](https://etherscan.io/address/0xA193b7d01E0e03b8F26214A54C7a515d9B4c8D43)
 - YfDaiFarmingUniswap address ["0xCBc033a017B1F6e4b359D2ABeD0C0e9623bb7D5A"](https://etherscan.io/address/0xCBc033a017B1F6e4b359D2ABeD0C0e9623bb7D5A)
 - FixedStaking30Days address ["0xff6d784d5938cb3980dce79bbacec53987d527d8"](https://etherscan.io/address/0xff6d784d5938cb3980dce79bbacec53987d527d8)
 - FixedStaking60Days address ["0x63aE7Ad4BC155561442207bB4a89a3FD697068D1"](https://etherscan.io/address/0x63aE7Ad4BC155561442207bB4a89a3FD697068D1)
 - FixedStaking90Days address ["0xa295338aB1a4A648D3578Da6940acfdEEFFD9B6F"](https://etherscan.io/address/0xa295338aB1a4A648D3578Da6940acfdEEFFD9B6F)
 
Install node packages (hardhat)

`yarn install`
 
## Testing deploy (rinkeby, matic)

Create local environments
```
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

Create local environments for matic-fork
```
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
export MATIC_UPSTREAM=https://matic-mainnet.chainstacklabs.com
```

Run ganache-cli docker container for deploy matic-fork
```
docker run --detach  --rm --publish 8546:8546 trufflesuite/ganache-cli:latest --mnemonic "${MNEMONIC}" --fork ${MATIC_UPSTREAM} --chainId 137
```

Run deploy matic-fork
```
npx hardhat --network matic-fork deploy --tags FixedStaking30Days,FixedStaking60Days,FixedStaking90Days
```

## Production deploy (mainnet, matic)

Create local environments for mainnet
```
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
export INFURA_API_KEY=<your API key>
```

Run deploy mainnet
```
npx hardhat --network mainnet deploy --tags FixedStaking30Days,FixedStaking60Days,FixedStaking90Days
npx hardhat --network mainnet etherscan-verify --solc-input --api-key <Etherscan_API_Key>
```

Create local environments for matic
```
export MNEMONIC='<your MNEMONIC phrase where you have balace>'
```

Run deploy matic
```
npx hardhat --network matic deploy --tags FixedStaking30Days,FixedStaking60Days,FixedStaking90Days
npx hardhat --network matic etherscan-verify --solc-input --api-key <Etherscan_API_Key>
```
