// const { getNamedAccounts, deployments, network } = require("hardhat")
// const {
//   networkConfig,
//   developmentChains,
//   VERIFICATION_BLOCK_CONFIRMATIONS,
// } = require("../helper-hardhat-config")
// const { autoFundCheck, verify } = require("../helper-functions")

// module.exports = async ({ getNamedAccounts, deployments }) => {
//   const { deploy, get, log } = deployments
//   const { deployer } = await getNamedAccounts()

//   const args = []
//   const fakeBoredApeYachtClub = await deploy("FakeBoredApeYachtClub", {
//     from: deployer,
//     args: args,
//     log: true,
//   })

//   log("FBAYC deployed")
// }

// module.exports.tags = ["all", "fbayc"]
