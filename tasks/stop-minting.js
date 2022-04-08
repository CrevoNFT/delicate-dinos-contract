task("stop-minting", "No more minting of any kind")
  .addParam("contract", "The address of the contract")
  .setAction(async ({ contract }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    await dinosContract.stopMint()
    console.log("Minting stopped")
  })
