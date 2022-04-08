task("open-drop-claim", "Unlocks the minting by claiming dropped dinos")
  .addParam("contract", "The address of the contract")
  .setAction(async ({ contract, fee }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    await dinosContract.startDropClaim()
    console.log("Drop claim started")
  })
