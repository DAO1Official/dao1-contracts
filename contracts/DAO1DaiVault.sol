// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface OldIERC20 {
    function transfer(address, uint256) external;
}

contract DAO1DaiVault is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint256 amount);
    event RewardsDisbursed(uint256 amount);

    // deposit token contract address and reward token contract address
    // these contracts are "trusted" and checked to not contain re-entrancy pattern
    // to safely avoid checks-effects-interactions where needed to simplify logic
    address public trustedDepositTokenAddress =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public trustedRewardTokenAddress =
        0xCE3f6f6672616c39D8B6858F8DAC9902eCa42C84;
    uint256 public constant LOCKUP_TIME = 120 days;

    uint256 public constant STAKING_FEE_RATE_X_100 = 50;
    uint256 public constant UNSTAKING_FEE_RATE_X_100 = 50;

    // Amount of tokens
    uint256 public disburseAmount = 8100e18;
    // To be disbursed continuously over this duration
    uint256 public disburseDuration = 180 days;

    // If there are any undistributed or unclaimed tokens left in contract after this time
    // Admin can claim them
    uint256 public adminCanClaimAfter = 200 days;

    // do not change this => disburse 100% rewards over `disburseDuration`
    uint256 public disbursePercentX100 = 100e2;

    uint256 public contractDeployTime;
    uint256 public adminClaimableTime;
    uint256 public lastDisburseTime;

    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(
            !(address(msg.sender).isContract()) && tx.origin == msg.sender,
            "No Contracts Allowed!"
        );
        _;
    }

    constructor() {
        contractDeployTime = block.timestamp;
        adminClaimableTime = contractDeployTime.add(adminCanClaimAfter);
        lastDisburseTime = contractDeployTime;
    }

    uint256 public totalClaimedRewards = 0;

    EnumerableSet.AddressSet private holders;

    mapping(address => uint256) public depositedTokens;
    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public lastClaimedTime;
    mapping(address => uint256) public totalEarnedTokens;
    mapping(address => uint256) public lastDivPoints;

    uint256 public totalTokensDisbursed = 0;
    uint256 public contractBalance = 0;

    uint256 public totalDivPoints = 0;
    uint256 public totalTokens = 0;

    uint256 internal pointMultiplier = 1e18;

    function addContractBalance(uint256 amount) public onlyOwner {
        require(
            IERC20(trustedRewardTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Cannot add balance!"
        );
        contractBalance = contractBalance.add(amount);
    }

    function updateAccount(address account) private {
        disburseTokens();
        uint256 pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(
                IERC20(trustedRewardTokenAddress).transfer(
                    account,
                    pendingDivs
                ),
                "Could not transfer tokens."
            );
            totalEarnedTokens[account] = totalEarnedTokens[account].add(
                pendingDivs
            );
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = block.timestamp;
        lastDivPoints[account] = totalDivPoints;
    }

    function getPendingDivs(address _holder) public view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint256 newDivPoints = totalDivPoints.sub(lastDivPoints[_holder]);

        uint256 depositedAmount = depositedTokens[_holder];

        uint256 pendingDivs = depositedAmount.mul(newDivPoints).div(
            pointMultiplier
        );

        return pendingDivs;
    }

    function getEstimatedPendingDivs(address _holder)
        public
        view
        returns (uint256)
    {
        uint256 pendingDivs = getPendingDivs(_holder);
        uint256 pendingDisbursement = getPendingDisbursement();
        if (contractBalance < pendingDisbursement) {
            pendingDisbursement = contractBalance;
        }
        uint256 depositedAmount = depositedTokens[_holder];
        if (depositedAmount == 0) return 0;
        if (totalTokens == 0) return 0;

        uint256 myShare = depositedAmount.mul(pendingDisbursement).div(
            totalTokens
        );

        return pendingDivs.add(myShare);
    }

    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }

    function deposit(uint256 amountToDeposit) external noContractsAllowed {
        require(
            block.timestamp.add(LOCKUP_TIME) <=
                contractDeployTime.add(disburseDuration),
            "Deposits are closed now!"
        );
        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");

        updateAccount(msg.sender);

        require(
            IERC20(trustedDepositTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amountToDeposit
            ),
            "Insufficient Token Allowance"
        );

        uint256 fee = amountToDeposit.mul(STAKING_FEE_RATE_X_100).div(100e2);
        uint256 amountAfterFee = amountToDeposit.sub(fee);

        require(
            IERC20(trustedDepositTokenAddress).transfer(owner(), fee),
            "Fee transfer failed!"
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(
            amountAfterFee
        );
        totalTokens = totalTokens.add(amountAfterFee);

        holders.add(msg.sender);
        depositTime[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amountToWithdraw) external noContractsAllowed {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens!");
        require(
            block.timestamp.sub(depositTime[msg.sender]) > LOCKUP_TIME,
            "You recently staked, please wait before withdrawing."
        );
        require(
            depositedTokens[msg.sender] >= amountToWithdraw,
            "Invalid amount to withdraw"
        );

        updateAccount(msg.sender);

        uint256 fee = amountToWithdraw.mul(UNSTAKING_FEE_RATE_X_100).div(100e2);
        uint256 amountAfterFee = amountToWithdraw.sub(fee);

        require(
            IERC20(trustedDepositTokenAddress).transfer(owner(), fee),
            "Fee transfer failed!"
        );

        require(
            IERC20(trustedDepositTokenAddress).transfer(
                msg.sender,
                amountAfterFee
            ),
            "Could not transfer tokens."
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(
            amountToWithdraw
        );
        totalTokens = totalTokens.sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    // withdraw without caring about Rewards
    function emergencyWithdraw(uint256 amountToWithdraw)
        external
        noContractsAllowed
    {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens!");
        require(
            block.timestamp.sub(depositTime[msg.sender]) > LOCKUP_TIME,
            "You recently staked, please wait before withdrawing."
        );
        require(
            depositedTokens[msg.sender] >= amountToWithdraw,
            "Invalid amount to withdraw"
        );

        // manual update account here without withdrawing pending rewards
        disburseTokens();
        lastClaimedTime[msg.sender] = block.timestamp;
        lastDivPoints[msg.sender] = totalDivPoints;

        uint256 fee = amountToWithdraw.mul(UNSTAKING_FEE_RATE_X_100).div(100e2);
        uint256 amountAfterFee = amountToWithdraw.sub(fee);

        require(
            IERC20(trustedDepositTokenAddress).transfer(owner(), fee),
            "Fee transfer failed!"
        );

        require(
            IERC20(trustedDepositTokenAddress).transfer(
                msg.sender,
                amountAfterFee
            ),
            "Could not transfer tokens."
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(
            amountToWithdraw
        );
        totalTokens = totalTokens.sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function claim() public {
        updateAccount(msg.sender);
    }

    function disburseTokens() private {
        uint256 amount = getPendingDisbursement();

        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount == 0 || totalTokens == 0) return;

        totalDivPoints = totalDivPoints.add(
            amount.mul(pointMultiplier).div(totalTokens)
        );
        totalTokensDisbursed = totalTokensDisbursed.add(amount);
        emit RewardsDisbursed(amount);

        contractBalance = contractBalance.sub(amount);
        lastDisburseTime = block.timestamp;
    }

    function getPendingDisbursement() public view returns (uint256) {
        uint256 timeDiff;
        uint256 _now = block.timestamp;
        uint256 _stakingEndTime = contractDeployTime.add(disburseDuration);
        if (_now > _stakingEndTime) {
            _now = _stakingEndTime;
        }
        if (lastDisburseTime >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastDisburseTime);
        }

        uint256 pendingDisburse = disburseAmount
        .mul(disbursePercentX100)
        .mul(timeDiff)
        .div(disburseDuration)
        .div(10000);
        return pendingDisburse;
    }

    function getHoldersList(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint256 listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }

    // function to allow owner to claim *other* modern ERC20 tokens sent to this contract
    function transferAnyERC20Token(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _tokenAddr != trustedDepositTokenAddress,
            "Admin cannot transfer out deposit tokens from this vault!"
        );
        require(
            (_tokenAddr != trustedRewardTokenAddress) ||
                (block.timestamp > adminClaimableTime),
            "Admin cannot Transfer out Reward Tokens Yet!"
        );
        require(
            IERC20(_tokenAddr).transfer(_to, _amount),
            "Could not transfer out tokens!"
        );
    }

    // function to allow owner to claim *other* modern ERC20 tokens sent to this contract
    function transferAnyOldERC20Token(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _tokenAddr != trustedDepositTokenAddress,
            "Admin cannot transfer out deposit tokens from this vault!"
        );
        require(
            (_tokenAddr != trustedRewardTokenAddress) ||
                (block.timestamp > adminClaimableTime),
            "Admin cannot Transfer out Reward Tokens Yet!"
        );

        OldIERC20(_tokenAddr).transfer(_to, _amount);
    }
}
