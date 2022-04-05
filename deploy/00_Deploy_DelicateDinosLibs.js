const { networkConfig } = require("../helper-hardhat-config")

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

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

  // await sleep(15000)

  // try {
  //   run("verify:verify", {
  //     address: delicateDinosMetadata.address,
  //     contract: "contracts/libs/DelicateDinosMetadata.sol:DelicateDinosMetadata",
  //     constructorArguments: [],
  //   })
  // } catch (error) {
  //   console.error(error)
  // }

  // try {
  //   run("verify:verify", {
  //     address: delicateDinosUpgrade.address,
  //     contract: "contracts/libs/DelicateDinosUpgrade.sol:DelicateDinosUpgrade",
  //     constructorArguments: [],
  //   })
  // } catch (error) {
  //   console.error(error)
  // }
}

module.exports.tags = ["all", "dinos_metadata_library"]
