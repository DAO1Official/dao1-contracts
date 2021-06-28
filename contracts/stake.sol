// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract DAO1FarmingUniswap is Ownable {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint amount);
    event RewardsDisbursed(uint amount);
    
    // deposit token contract address and reward token contract address
    // these contracts are "trusted" and checked to not contain re-entrancy pattern 
    // to safely avoid checks-effects-interactions where needed to simplify logic
    address public trustedDepositTokenAddress = 0xF94556124786E08171d278a75cf1b46eE9592227;
    address public trustedRewardTokenAddress = 0xCE3f6f6672616c39D8B6858F8DAC9902eCa42C84; 
    
    uint public constant STAKING_FEE_RATE_X_100 = 50;
    uint public constant UNSTAKING_FEE_RATE_X_100 = 50;

    // Amount of tokens
    uint public disburseAmount = 5400e18;
    // To be disbursed continuously over this duration
    uint public disburseDuration = 180 days;
    
    // If there are any undistributed or unclaimed tokens left in contract after this time
    // Admin can claim them
    uint public adminCanClaimAfter = 200 days;
    
    
    // do not change this => disburse 100% rewards over `disburseDuration`
    uint public disbursePercentX100 = 100e2;
    
    uint public contractDeployTime;
    uint public adminClaimableTime;
    uint public lastDisburseTime;
    
    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }
    
    constructor() {
        contractDeployTime = block.timestamp;
        adminClaimableTime = contractDeployTime.add(adminCanClaimAfter);
        lastDisburseTime = contractDeployTime;
    }
    
    struct Position {
        uint256 depositTime;
        uint256 period;
        uint256 amount;
        uint256 positionId;
        bool status;
    }

    uint public totalClaimedRewards = 0;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => Position[]) depositedTokens;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    mapping (address => uint) public lastDivPoints;
    
    uint public totalTokensDisbursed = 0;
    uint public contractBalance = 0;
    
    uint public totalDivPoints = 0;
    uint public totalTokens = 0;

    uint internal pointMultiplier = 1e18;
    
    function addContractBalance(uint amount) public onlyOwner {
        require(IERC20(trustedRewardTokenAddress).transferFrom(msg.sender, address(this), amount), "Cannot add balance!");
        contractBalance = contractBalance.add(amount);
    }
    
    
    function updateAccount(address account) private {
        disburseTokens();
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(IERC20(trustedRewardTokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = block.timestamp;
        lastDivPoints[account] = totalDivPoints;
    }
    
    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (getPositions(_holder).length == 0) return 0;
        
        uint newDivPoints = totalDivPoints.sub(lastDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];
        
        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);
            
        return pendingDivs;
    }
    
    function getEstimatedPendingDivs(address _holder) public view returns (uint) {
        uint pendingDivs = getPendingDivs(_holder);
        uint pendingDisbursement = getPendingDisbursement();
        if (contractBalance < pendingDisbursement) {
            pendingDisbursement = contractBalance;
        }
        uint depositedAmount = depositedTokens[_holder];
        if (depositedAmount == 0) return 0;
        if (totalTokens == 0) return 0;
        
        uint myShare = depositedAmount.mul(pendingDisbursement).div(totalTokens);
                                
        return pendingDivs.add(myShare);
    }
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }

    function getPositions(address holder) public view returns (Position[] memory) {
        Position[] memory ValidPosition;
         for (uint256 i = 0; i < depositedTokens[holder].length; i++) {
            if (depositedTokens[holder][i].status==true){
                ValidPosition[i]=depositedTokens[holder][i];
            }
        }
        return ValidPosition;
    }
    
    function deposit(uint256 amountToDeposit, uint256 period) external noContractsAllowed {
        require(block.timestamp.add(period* 1 days) <= contractDeployTime.add(disburseDuration), "Deposits are closed now!");
        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");
        
        updateAccount(msg.sender);
        
        require(IERC20(trustedDepositTokenAddress).transferFrom(msg.sender, address(this), amountToDeposit), "Insufficient Token Allowance");
        
        uint fee = amountToDeposit.mul(STAKING_FEE_RATE_X_100).div(100e2);
        uint amountAfterFee = amountToDeposit.sub(fee);
        
        // require(Token(trustedDepositTokenAddress).transfer(owner, fee), "Fee transfer failed!");
        depositedTokens[msg.sender].push(Position(block.timestamp,period,amountToDeposit,depositedTokens[msg.sender].length,true));
        totalTokens = totalTokens.add(amountAfterFee);
        holders.add(msg.sender);
    }
    
    function withdraw(uint positionId) external noContractsAllowed {
        require(positionId<=depositedTokens[msg.sender].length.sub(1));
        Position withdraw_position=depositedTokens[msg.sender][positionId];
        require(block.timestamp.sub(withdraw_position.depositTime) < withdraw_position.period* 1 days, "You recently staked, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        uint fee = withdraw_position.amount.mul(UNSTAKING_FEE_RATE_X_100).div(100e2);
        uint amountAfterFee = withdraw_position.amount.sub(fee);
        
        // require(Token(trustedDepositTokenAddress).transfer(owner, fee), "Fee transfer failed!");
        
        require(IERC20(trustedDepositTokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        withdraw_position.status = false;
        totalTokens = totalTokens.sub(withdraw_position.amount);
        
        if (getPositions(msg.sender).length == 0) {
            holders.remove(msg.sender);
        }
    }
    
    // withdraw without caring about Rewards
    function emergencyWithdraw(uint positionId) external noContractsAllowed {
        require(positionId<=depositedTokens[msg.sender].length.sub(1));
        Position withdraw_position=depositedTokens[msg.sender][positionId];
        require(block.timestamp.sub(withdraw_position.depositTime) < withdraw_position.period * 1 days, "You recently staked, please wait before withdrawing.");
        
        // manual update account here without withdrawing pending rewards
        disburseTokens();
        lastClaimedTime[msg.sender] = block.timestamp;
        lastDivPoints[msg.sender] = totalDivPoints;
        
        uint fee = withdraw_position.amount.mul(UNSTAKING_FEE_RATE_X_100).div(100e2);
        uint amountAfterFee = withdraw_position.amount.sub(fee);
        
        require(IERC20(trustedDepositTokenAddress).transfer(owner(), fee), "Fee transfer failed!");
        
        require(IERC20(trustedDepositTokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
        
        withdraw_position.status = false;
        totalTokens = totalTokens.sub(withdraw_position.amount);
        
        if (getPositions(msg.sender).length == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claim() public {
        updateAccount(msg.sender);
    }
    
    function disburseTokens() private {
        uint amount = getPendingDisbursement();

        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount == 0 || totalTokens == 0) return;
        
        totalDivPoints = totalDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        totalTokensDisbursed = totalTokensDisbursed.add(amount);
        emit RewardsDisbursed(amount);
        
        contractBalance = contractBalance.sub(amount);
        lastDisburseTime = block.timestamp;
        
    }
    
    function getPendingDisbursement() public view returns (uint) {
        uint timeDiff;
        uint _now = block.timestamp;
        uint _stakingEndTime = contractDeployTime.add(disburseDuration);
        if (_now > _stakingEndTime) {
            _now = _stakingEndTime;
        }
        if (lastDisburseTime >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastDisburseTime);   
        }
        
        uint pendingDisburse = disburseAmount
                                    .mul(disbursePercentX100)
                                    .mul(timeDiff)
                                    .div(disburseDuration)
                                    .div(10000);
        return pendingDisburse;
    }
    
    function getHoldersList(uint startIndex, uint endIndex) 
        public 
        view 
        returns (address[] memory stakers, 
            uint[] memory stakingTimestamps, 
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);
        
        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);
        
        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }
        
        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }
    

    // function to allow owner to claim *other* modern ERC20 tokens sent to this contract
    function transferAnyERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        
        require(_tokenAddr != trustedDepositTokenAddress, "Admin cannot transfer out deposit tokens from this vault!");
        require((_tokenAddr != trustedRewardTokenAddress) || (block.timestamp > adminClaimableTime), "Admin cannot Transfer out Reward Tokens Yet!");
        require(IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");
    }
    
    // function to allow owner to claim *other* modern ERC20 tokens sent to this contract
    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        
        require(_tokenAddr != trustedDepositTokenAddress, "Admin cannot transfer out deposit tokens from this vault!");
        require((_tokenAddr != trustedRewardTokenAddress) || (block.timestamp > adminClaimableTime), "Admin cannot Transfer out Reward Tokens Yet!");
        
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}