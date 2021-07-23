module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const DAO1 = await ethers.getContract("DAO1")
  const token = DAO1.address
  const stakeDurationDays = 2
  const rewardRate = 450
  const earlyUnstakeFee = 450

  await deploy("FixedStaking2Days", {
    from: deployer,
    log: true,
    args: [token, stakeDurationDays, rewardRate, earlyUnstakeFee],
    contract: "FixedStaking",
  })
}

module.exports.tags = ["FixedStaking2Days"]
module.exports.dependencies = ["DAO1Token"]
