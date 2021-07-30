const contractName = "FixedStaking60Days"
const DAO1Address = process.env.DAO1Address

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  const token = DAO1Address || (await ethers.getContract("DAO1")).address
  const stakeDurationDays = 60
  const rewardRate = 450
  const earlyUnstakeFee = 450

  console.log("Deploying contract:", contractName)
  console.log("Deployer:", deployer)
  console.log("Arguments:", token, stakeDurationDays, rewardRate, earlyUnstakeFee)

  await deploy(contractName, {
    from: deployer,
    log: true,
    args: [token, stakeDurationDays, rewardRate, earlyUnstakeFee],
    contract: "FixedStaking",
  })

  await execute(contractName,
    {
      from: deployer,
      log: true
    },
    "start"
  )
}

module.exports.tags = [contractName]
if (!DAO1Address) {
  module.exports.dependencies = ["DAO1Token"]
}
