const { networkConfig } = require("../helper-hardhat-config")

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = await getChainId()

  const cfg = networkConfig[chainId]
  const args = [cfg.vrfCoordinator, cfg.linkToken, cfg.keyHash, cfg.fee]
  const metadataLibraryAddress = (await get("DelicateDinosMetadata")).address
  const upgradeLibraryAddress = (await get("DelicateDinosUpgrade")).address
  const delicateDinos = await deploy("DelicateDinos", {
    from: deployer,
    args: args,
    log: true,
    libraries: {
      DelicateDinosMetadata: metadataLibraryAddress,
      DelicateDinosUpgrade: upgradeLibraryAddress,
    },
  })

  log("Delicate Dinos deployed")

  await sleep(10000)

  try {
    run("verify:verify", {
      address: delicateDinos.address,
      contract: "contracts/DelicateDinos.sol:DelicateDinos",
      constructorArguments: [cfg.vrfCoordinator, cfg.linkToken, cfg.keyHash, cfg.fee],
    })
  } catch (error) {
    console.error(error)
  }
}

module.exports.tags = ["all", "dinos_nft"]
