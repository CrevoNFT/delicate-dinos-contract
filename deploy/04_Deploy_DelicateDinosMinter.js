const { networkConfig } = require("../helper-hardhat-config")

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const delicateDinosAddress = (await get("DelicateDinos")).address
  const args = [delicateDinosAddress]
  const minter = await deploy("DelicateDinosMinter", {
    from: deployer,
    args: args,
    log: true,
  })

  log("Minter Contract deployed")(
    // set auth in Delicate Dinos
    await ethers.getContractAt("DelicateDinos", delicateDinosAddress)
  ).setMinterContract(minter.address)

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
