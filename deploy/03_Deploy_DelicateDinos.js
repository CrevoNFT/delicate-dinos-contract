const { networkConfig } = require("../helper-hardhat-config")

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const metadataLibraryAddress = (await get("DelicateDinosMetadata")).address
  const upgradeLibraryAddress = (await get("DelicateDinosUpgrade")).address
  const dinoUpTokenAddress = (await get("DinoUpToken")).address
  const randomnessProviderAddress = (await get("DelicateDinosRandomness")).address
  const raffleContractAddress = (await get("DelicateDinosRaffle")).address
  const args = [randomnessProviderAddress, raffleContractAddress, dinoUpTokenAddress]
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

  // set delicateDinos as master of randomness provider
  const randomnessProvider = await ethers.getContractAt(
    "DelicateDinosRandomness",
    randomnessProviderAddress
  )
  await randomnessProvider.initMaster(delicateDinos.address)

  // await sleep(15000)

  // try {
  //   run("verify:verify", {
  //     address: delicateDinos.address,
  //     contract: "contracts/DelicateDinos.sol:DelicateDinos",
  //     constructorArguments: [cfg.vrfCoordinator, cfg.linkToken, cfg.keyHash, cfg.fee],
  //   })
  // } catch (error) {
  //   console.error(error)
  // }
}

module.exports.tags = ["all", "dinos_nft"]
