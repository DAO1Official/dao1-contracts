//const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai")
const { BigNumber } = require("ethers")
//const { ZERO_ADDRESS } = constants;

describe("DAO1Stake", function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.owner = this.signers[0]
    this.alice = this.signers[1]
    this.bob = this.signers[2]

    this.token = await ethers.getContractFactory("DAO1")
    this.contract = await ethers.getContractFactory("DAO1DaiVaultMock")
  })

  beforeEach(async function () {
    this.depositToken = await this.token.deploy("DAO1", "DAO1", this.owner.address)
    this.rewardToken = await this.token.deploy("DAO2", "DAO2", this.owner.address)
    this.pool = await this.contract.deploy(this.depositToken.address, this.rewardToken.address)

    this.alice_balance_depositToken = 20000
    this.alice_deposit = 10000
    this.fee = 0.005

    await this.depositToken.transfer(this.alice.address, this.alice_balance_depositToken)
    await this.depositToken.connect(this.alice).approve(this.pool.address, this.alice_balance_depositToken)

    owner_balance = await this.depositToken.balanceOf(this.owner.address)
    await this.depositToken.transfer(this.bob.address, owner_balance)

    await this.pool.connect(this.alice).deposit(this.alice_deposit)
  })

  it("should be deployed", async function () {
    const deployed = await this.pool.deployed()
    expect(deployed, true)
  })

  it("should have correct state variables", async function () {
    expect(await this.pool.owner()).to.equal(this.owner.address)
  })

  describe("deposit function", function () {
    it("deposit token on stake contract", async function () {
      contract_balance = await this.depositToken.balanceOf(this.pool.address)
      expected_balance = BigNumber.from((this.alice_deposit * (1 - this.fee)).toString())
      expect(expected_balance).to.equal(contract_balance)
    })

    it("increase in the total number of deposit tokens during the deposit", async function () {
      contract_balance = await this.pool.totalTokens()
      expected_balance = BigNumber.from((this.alice_deposit * (1 - this.fee)).toString())
      expect(expected_balance).to.equal(contract_balance)
    })

    it("creating a position for the user", async function () {
      deposit = await this.pool.depositedTokens(this.alice.address)
      depositTime = await this.pool.depositTime(this.alice.address)
      blockTime = await network.provider.send("eth_getBlockByNumber", ["latest", false])
      expect(blockTime.timestamp).to.equal(depositTime._hex)
      expected_deposit = BigNumber.from((this.alice_deposit * (1 - this.fee)).toString())
      expect(deposit).to.equal(expected_deposit)
    })

    it("owner receives fee for the deposit", async function () {
      ownerBalance = await this.depositToken.balanceOf(this.owner.address)
      balance = BigNumber.from((this.alice_deposit * this.fee).toString())
      expect(ownerBalance).to.equal(balance)
    })

    it("getting a reward for not the first deposits // bad work?", async function () {
      await this.rewardToken.approve(this.pool.address, 1000000)
      await this.pool.addContractBalance(1000000)

      total_reward = await this.pool.contractBalance()
      //expect(balance2).to.equal(100000);

      balance1 = await this.rewardToken.balanceOf(this.alice.address)
      balance4 = await this.pool.contractBalance()
      await this.pool.connect(this.alice).deposit(this.alice_deposit,{from:this.alice.address});
      //await this.pool.connect(this.alice).claim()
      balance2 = await this.rewardToken.balanceOf(this.alice.address)
      balance3 = await this.pool.contractBalance()

      console.log("total number of reward tokens", total_reward.toString())
      console.log("initial balance of reward tokens", balance1.toString())
      console.log("the balance of reward tokens after receiving the reward", balance2.toString())
    })

    it("can't deposit 0 token", async function () {
      await expect(this.pool.deposit(0)).to.be.revertedWith("Cannot deposit 0 Tokens")
    })
    //it("can't deposit more than the balance", async function() {
    //  await expect(this.pool.deposit(ownerBalance,period1)).to.be.revertedWith("Insufficient Token Allowance");
    //});
    // !!!! TODO: outputs the ERC20 error code of the contract, then whether it is necessary to check this operation in the contract using require?
    it("not possible to make a deposit after the specified days from the date of creation of the contract", async function () {
      disburseDuration = await this.pool.disburseDuration()
      LOCKUP_TIME = await this.pool.LOCKUP_TIME()
      work_contract_time = disburseDuration - LOCKUP_TIME
      await network.provider.send("evm_increaseTime", [work_contract_time + 1])
      await expect(this.pool.deposit(this.alice_deposit)).to.be.revertedWith("Deposits are closed now!")
    })
  })

  // describe("getPosition function", function() {
  //   it("index out of range", async function() {
  //     await expect(DAO1Stake.getPosition(owner.address,5)).to.be.revertedWith("index out of range");
  //   });
  //   it("get position by position id", async function() {
  //     ZeroPosition=await DAO1Stake.getPosition(owner.address,0);
  //     amount=BigNumber.from(amount1.toString())
  //     period=BigNumber.from(period1.toString())
  //     expect(ZeroPosition["depositTime"]).to.equal(time)
  //     expect(ZeroPosition["period"]).to.equal(period);;
  //     expect(ZeroPosition["amount"]).to.equal(amount);
  //     expect(ZeroPosition["status"]).to.equal(true);

  //   });

  // });

  // describe("withdraw function", function() { // write checks that the tokens were actually debited from the contract to the owner's address
  //   it("index out of range", async function() {
  //     await expect(DAO1Stake.withdraw(5)).to.be.revertedWith("index out of range");
  //   });
  //   it("you can't withdraw until the stake period has passed", async function() {
  //     await expect(DAO1Stake.withdraw(0)).to.be.revertedWith("You recently staked, please wait before withdrawing.");
  //   });
  //   it("withdraw when stake period has passed", async function() {
  //     count=BigNumber.from("2");
  //     time=BigNumber.from((period1*24*60*60+1).toString())

  //     await DAO1Stake.setCurrentBlockTime(time);
  //     await DAO1Stake.withdraw(0);

  //     contract_balance = await DAO1.balanceOf(DAO1Stake.address);
  //     holder_balance = await DAO1.balanceOf(owner.address);
  //     expect(contract_balance).to.equal(BigNumber.from((amount-amount1).toString()))
  //     balance=BigNumber.from("3599999999999999999999850") // the initial balance, set in the dao1 smart contract minus amount2, amount3
  //     expect(holder_balance).to.equal(balance)

  //     ZeroPosition=await DAO1Stake.getPosition(owner.address,0);
  //     amount0=BigNumber.from(amount1.toString())
  //     period0=BigNumber.from(period1.toString())
  //     time0=BigNumber.from("0")
  //     if ((ZeroPosition["depositTime"]._hex===time0._hex) && (ZeroPosition["period"]._hex===period0._hex) && (ZeroPosition["amount"]._hex===amount0._hex)){
  //       expect(1).to.equal(0);
  //     }

  //     await DAO1Stake.withdraw(0);
  //     ZeroPosition2=await DAO1Stake.getPosition(owner.address,0);
  //     if ((ZeroPosition["depositTime"]._hex===ZeroPosition2["depositTime"]._hex) && (ZeroPosition["period"]._hex===ZeroPosition2["period"]._hex) && (ZeroPosition["amount"]._hex===ZeroPosition2["amount"]._hex)){
  //       expect(2).to.equal(0);
  //      }
  //   });
  // });

  // describe("CountPositions mapping", function() {
  //   it("initial zero counter", async function() {
  //     count=BigNumber.from("0");
  //     expect(await DAO1Stake.CountPositions(this.alice.address)).to.equal(count);
  //   });
  //   it("increasing the counter when making a deposit", async function() {
  //     count=BigNumber.from("3");
  //     expect(await DAO1Stake.CountPositions(owner.address)).to.equal(count);
  //   });
  //   it("reducing the counter when withdrawing position", async function() {
  //     count=BigNumber.from("2");
  //     time=BigNumber.from((period1*24*60*60+1).toString())
  //     await DAO1Stake.setCurrentBlockTime(time);
  //     await DAO1Stake.withdraw(0);
  //     expect(await DAO1Stake.CountPositions(owner.address)).to.equal(count);

  //   });
  //   });
})
