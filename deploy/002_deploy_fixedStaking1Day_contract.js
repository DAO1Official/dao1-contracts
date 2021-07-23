module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const DAO1 = await ethers.getContract("DAO1")
  const token = DAO1.address
  const stakeDurationDays = 1
  const rewardRate = 155
  const earlyUnstakeFee = 155

  await deploy("FixedStaking1Day", {
    from: deployer,
    log: true,
    args: [token, stakeDurationDays, rewardRate, earlyUnstakeFee],
    contract: "FixedStaking",
  })

}

module.exports.tags = ["FixedStaking1Day"]
module.exports.dependencies = ["DAO1Token"]
