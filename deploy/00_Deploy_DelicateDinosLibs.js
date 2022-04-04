const { networkConfig } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()
  const delicateDinosMetadata = await deploy("DelicateDinosMetadata", {
    from: deployer,
    args: [],
    log: true,
  })
  log("Delicate Dinos Metadata Library deployed")
  const delicateDinosUpgrade = await deploy("DelicateDinosUpgrade", {
    from: deployer,
    args: [],
    log: true,
  })
  log("Delicate Dinos Upgrade Library deployed")
}

module.exports.tags = ["all", "dinos_metadata_library"]
