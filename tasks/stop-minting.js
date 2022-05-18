task("stop-minting", "No more minting of any kind")
  .addParam("contract", "The address of the MINTER contract")
  .setAction(async ({ contract }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinosMinter", contract)
    await dinosContract.stopMint()
    console.log("Minting stopped")
  })
