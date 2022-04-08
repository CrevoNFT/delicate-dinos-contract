const getRootHash = require("../whitelist/merkle_tree")

task(
  "open-whitelist-sale",
  "Opens a whitelist sale for given contract using addresses in whitelist/whitelist.json"
)
  .addParam("contract", "The address of the contract")
  .addParam("fee", "The minting fee (MATIC)")
  .setAction(async ({ contract, fee }, { ethers }) => {
    const rootHash = getRootHash()
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    await dinosContract.startWhitelistMint(rootHash, ethers.utils.parseEther(fee))
    console.log("whitelisted sale started for addresses in whitelist/whitelist.json with fee ", fee)
  })
