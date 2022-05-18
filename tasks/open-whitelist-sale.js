const getRootHash = require("../whitelist/merkle_tree")

task(
  "open-whitelist-sale",
  "Opens a whitelist sale for given contract using addresses in whitelist/whitelist.json"
)
  .addParam("contract", "The address of the MINTER contract")
  .addParam("fee", "The minting fee (MATIC)")
  .addParam("max", "The max number of Dinos mintable per whitelisted address")
  .setAction(async ({ contract, fee, maxMintable }, { ethers }) => {
    const rootHash = getRootHash()
    const dinosContract = await ethers.getContractAt("DelicateDinosMinter", contract)
    await dinosContract.startWhitelistMint(rootHash, ethers.utils.parseEther(fee), maxMintable)
    console.log(
      "whitelisted sale started for addresses in whitelist/whitelist.json with fee ",
      fee,
      " and max mintable ",
      maxMintable
    )
  })
