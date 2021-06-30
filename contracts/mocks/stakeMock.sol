
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../stake.sol";

contract DAO1StakeMock is DAO1Stake {
    uint256 private currentBlockTime;

    constructor(address _DepositToken,address _RewardToken) DAO1Stake(_DepositToken, _RewardToken)
    {}

    function setCurrentBlockTime(uint256 _currentBlockTime) public {
        currentBlockTime = _currentBlockTime;
    }

    function _getCurrentBlockTime() override internal view returns (uint256) {
        return currentBlockTime;
    }
}