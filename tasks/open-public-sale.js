task("open-public-sale", "Opens a public sale for given contract")
  .addParam("contract", "The address of the MINTER contract")
  .addParam("initialPrice", "The initial minting fee (MATIC)")
  .addParam("minPrice", "The minimum minting fee (MATIC)")
  .addParam("intervalDecrement", "The minting fee decrement per tier interval")
  .addParam("tierInterval", "The duration of a tier interval in MINUTES")
  .addParam("maxMintable", "The max number of Dinos mintable per address")
  .setAction(
    async (
      { contract, initialPrice, minPrice, intervalDecrement, tierInterval, maxMintable },
      { ethers }
    ) => {
      const dinosContract = await ethers.getContractAt("DelicateDinosMinter", contract)
      await dinosContract.startPublicSale(
        ethers.utils.parseEther(initialPrice),
        ethers.utils.parseEther(minPrice),
        ethers.utils.parseEther(intervalDecrement),
        ethers.utils.parseEther(tierInterval),
        maxMintable
      )
      console.log("public sale started with fee ", fee, " and max mintable ", maxMintable)
    }
  )
