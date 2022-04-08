const fs = require("fs")

task("drop-dinos", "Drops dinos by lottery")
  .addParam("contract", "The address of the contract")
  .setAction(async ({ contract }, { ethers }) => {
    const dinosContract = await ethers.getContractAt("DelicateDinos", contract)
    let favouredIds, favourFactor
    try {
      const fileData = fs.readFileSync(`drop/drop.json`, { encoding: "utf8", flag: "r" })
      const lotterySetup = JSON.parse(fileData)
      favouredIds = lotterySetup.favouredTokenIds
      favourFactor = lotterySetup.favourFactor
      console.log(favouredIds.length, " tokenIDs in Favoured List")
      console.log(favourFactor, " Favour Factor")
    } catch (e) {
      console.error(e)
    }
    await dinosContract.startDrop(favouredIds, favourFactor)
    console.log("Drop claim started... Waiting for Chainlink to finish...")

    await new Promise(async (resolve, reject) => {
      try {
        filter = {
          address: contract,
          topics: [utils.id("DropFinished()")],
        }
        dinosContract.on(filter, () => {
          console.log("Drop Finished")
          resolve()
        })
      } catch (e) {
        reject(e)
      }
    })
  })
