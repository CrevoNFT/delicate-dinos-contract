task("open-public-sale", "Opens a public sale for given contract")
  .addParam("contract", "The address of the MINTER contract")
  .addParam("fee", "The minting fee (MATIC)")
  .addParam("max", "The max number of Dinos mintable per address")
  .setAction(async ({ contract, fee, maxMintable }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinosMinter", contract)
    await dinosContract.startPublicSale(ethers.utils.parseEther(fee), maxMintable)
    console.log("public sale started with fee ", fee, " and max mintable ", maxMintable)
  })
