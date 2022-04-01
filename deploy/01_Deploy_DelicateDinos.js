const { networkConfig } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = await getChainId()

  const cfg = networkConfig[chainId]
  const args = [cfg.vrfCoordinator, cfg.linkToken, cfg.keyHash, cfg.fee]
  const metadataLibraryAddress = (await get("DelicateDinosMetadata")).address
  const delicateDinos = await deploy("DelicateDinos", {
    from: deployer,
    args: args,
    log: true,
    libraries: { DelicateDinosMetadata: metadataLibraryAddress },
  })

  log("Delicate Dinos deployed")
}

module.exports.tags = ["all", "dinos_nft"]
