const { networkConfig } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = 4 // rinkeby;
  // const chainId = 80001 // mumbai;

  const cfg = networkConfig[chainId]
  const delicateDinosMetadata = await deploy("DelicateDinosMetadata", {
    from: deployer,
    args: [],
    log: true,
  })

  log("Delicate Dinos Metadata Library deployed")
}

module.exports.tags = ["all", "dinos_metadata_library"]
