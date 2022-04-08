task("open-public-sale", "Opens a public sale for given contract")
  .addParam("contract", "The address of the contract")
  .addParam("fee", "The minting fee (MATIC)")
  .setAction(async ({ contract, fee }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    await dinosContract.startPublicSale(ethers.utils.parseEther(fee))
    console.log("public sale started with fee ", fee)
  })
