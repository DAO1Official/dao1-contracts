module.exports = async function ({ getNamedAccounts, deployments }) {

  const { deployer, tester1, tester2 } = await getNamedAccounts()

  const DAO1 = await ethers.getContract("DAO1")
  const FixedStaking1Day = await ethers.getContract("FixedStaking1Day")
  const FixedStaking2Days = await ethers.getContract("FixedStaking2Days")
  const FixedStaking3Days = await ethers.getContract("FixedStaking3Days")

  let amount = ethers.utils.parseUnits("900000", 18)
  await (await DAO1.transfer(FixedStaking1Day.address, amount)).wait()
  await (await DAO1.transfer(FixedStaking2Days.address, amount)).wait()
  await (await DAO1.transfer(FixedStaking3Days.address, amount)).wait()

  let balance = await DAO1.balanceOf(FixedStaking1Day.address)
  console.log("Balance (FixedStaking1Day):",
    FixedStaking1Day.address,
    ethers.utils.formatEther(balance, 18)
  )

  balance = await DAO1.balanceOf(FixedStaking2Days.address)
  console.log("Balance (FixedStaking2Days):",
    FixedStaking2Days.address,
    ethers.utils.formatEther(balance, 18)
  )

  balance = await DAO1.balanceOf(FixedStaking3Days.address)
  console.log("Balance (FixedStaking3Days):",
    FixedStaking3Days.address,
    ethers.utils.formatEther(balance, 18)
  )

  amount = ethers.utils.parseUnits("100000", 18)
  await (await DAO1.transfer(tester1, amount)).wait()
  await (await DAO1.transfer(tester2, amount)).wait()

  balance = await DAO1.balanceOf(deployer)
  console.log("Balance (Deployer):",
    deployer,
    ethers.utils.formatEther(balance, 18)
  )

  balance = await DAO1.balanceOf(tester1)
  console.log("Balance (Tester1):",
    tester1,
    ethers.utils.formatEther(balance, 18)
  )

  balance = await DAO1.balanceOf(tester2)
  console.log("Balance (Tester2):",
    tester2,
    ethers.utils.formatEther(balance, 18)
  )
}

module.exports.tags = ["TransferDAO1"]
module.exports.dependencies = ["DAO1Token", "FixedStaking1Day", "FixedStaking2Days", "FixedStaking3Days"]
