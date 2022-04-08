task("go-impact", "Affect dinos with impact")
  .addParam("contract", "The address of the contract")
  .setAction(async ({ contract }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    await dinosContract.impact()
    console.log("Impact started... Waiting for Chainlink to finish...")

    await new Promise(async (resolve, reject) => {
      try {
        filter = {
          address: contract,
          topics: [utils.id("DinoDamaged(uint8)")],
        }
        dinosContract.on(filter, () => {
          console.log("Impact Finished")
          resolve()
        })
      } catch (e) {
        reject(e)
      }
    })
  })
