module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const name = "DAO1"
  const symbol = "DAO1"
  const toAddress = deployer

  await deploy("DAO1", {
    from: deployer,
    log: true,
    args: [name, symbol, toAddress],
    skipIfAlreadyDeployed: true
  })
}

module.exports.tags = ["DAO1Token"]
