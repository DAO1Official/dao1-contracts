//const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { BigNumber } = require('ethers');
//const { ZERO_ADDRESS } = constants;


describe("DAO1Stake", function() {
  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
    DAO1 = await ethers.getContractFactory("DAO1");
    DAO1 = await DAO1.deploy("DAO1","DAO1",owner.address);
    //  console.log(DAO1)
    DAO1Stake = await ethers.getContractFactory("DAO1Stake");
    DAO1Stake = await DAO1Stake.deploy(DAO1.address,DAO1.address);

    ownerBalance = await DAO1.balanceOf(owner.address);
    await DAO1.approve(DAO1Stake.address,ownerBalance,{from:owner.address})

    amount1=30;
    amount2=60;
    amount3=90;
    period1=60;
    period2=30;
    period3=90;
    amount=amount1+amount2+amount3
    amount=BigNumber.from(amount.toString());
    await DAO1Stake.deposit(amount1,period1);
    await DAO1Stake.deposit(amount2,period2);
    await DAO1Stake.deposit(amount3,period3);
  });
  describe("deposit function", function() {
    it("deposit token on stake contract", async function() {
      const contract_balance = await DAO1.balanceOf(DAO1Stake.address);
      expect(amount).to.equal(contract_balance);
    });
    it("can't deposit 0 token", async function() {
      await expect(DAO1Stake.deposit(0,period1)).to.be.revertedWith("Cannot deposit 0 Tokens");
    });
    //it("can't deposit more than the balance", async function() {
    //  await expect(DAO1Stake.deposit(ownerBalance,period1)).to.be.revertedWith("Insufficient Token Allowance");
    //});
    it("creating a position for the user", async function() {
      position= await DAO1Stake.getPosition(owner.address,0)
      //console.log(position)
    });
  });

  describe("withdrow function", function() {
    it("deposit token on stake contract", async function() {
      const contract_balance = await DAO1.balanceOf(DAO1Stake.address);
      expect(amount).to.equal(contract_balance);
    });
    it("can't deposit 0 token", async function() {
      await expect(DAO1Stake.deposit(0,period1)).to.be.revertedWith("Cannot deposit 0 Tokens");
    });
    //it("can't deposit more than the balance", async function() {
    //  await expect(DAO1Stake.deposit(ownerBalance,period1)).to.be.revertedWith("Insufficient Token Allowance");
    //});
    it("creating a position for the user", async function() {
      position= await DAO1Stake.getPosition(owner.address,0)
      //console.log(position)
    });
  });

  describe("CountPositions function", function() {
    it("initial zero counter", async function() {
      count=BigNumber.from("0");
      expect(await DAO1Stake.CountPositions(addr1.address)).to.equal(count);
    });
    it("increasing the counter when making a deposit", async function() {
      count=BigNumber.from("3");
      expect(await DAO1Stake.CountPositions(owner.address)).to.equal(count);
    });
    it("reducing the counter when withdrawing position", async function() {
      count=BigNumber.from("2");
      await DAO1Stake.setCurrentBlock("10000")
      await DAO1Stake.withdraw(0,{from: owner.address});
      expect(await DAO1Stake.CountPositions(owner.address)).to.equal(count);

    });
  });

});