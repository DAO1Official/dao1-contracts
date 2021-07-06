
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../DAO1DaiVault.sol";

contract DAO1DaiVaultMock is DAO1DaiVault {
    constructor(address deposit,address reward){
        trustedDepositTokenAddress = deposit;
        trustedRewardTokenAddress = reward;
    }

}