module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const args = []
  const delicateDinos = await deploy("DelicateDinos", {
    from: deployer,
    args: args,
    log: true,
  })

  log("Delicate Dinos deployed")
}

module.exports.tags = ["all", "dinos_nft"]
