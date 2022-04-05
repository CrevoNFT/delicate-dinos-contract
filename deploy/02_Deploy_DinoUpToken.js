const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const args = []
  const dinoUpToken = await deploy("DinoUpToken", {
    from: deployer,
    args: args,
    log: true,
  })

  log("Dino Up Token deployed")

  // await sleep(15000)

  // try {
  //   run("verify:verify", {
  //     address: dinoUpToken.address,
  //     contract: "contracts/DinoUpToken.sol:DinoUpToken",
  //     constructorArguments: [],
  //   })
  // } catch (error) {
  //   console.error(error)
  // }
}

module.exports.tags = ["all", "dino_up_token"]
