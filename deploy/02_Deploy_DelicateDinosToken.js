module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, log } = deployments
  const { deployer } = await getNamedAccounts()

  const args = []
  const delicateDinosToken = await deploy("DelicateDinosToken", {
    from: deployer,
    args: args,
    log: true,
  })

  log("Delicate Dinos deployed")
}

module.exports.tags = ["all", "dinos_token"]
