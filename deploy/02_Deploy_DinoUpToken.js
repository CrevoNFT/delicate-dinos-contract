module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const args = []
  const dinoUpToken = await deploy("DinoUpToken", {
    from: deployer,
    args: args,
    log: true,
  })

  log("Dino Up Token deployed")
}

module.exports.tags = ["all", "dino_up_token"]