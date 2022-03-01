const utils = require("./utils");
const fs = require("fs");
module.exports = async function getLatestDeployment(
  hre,
  contractName,
  verbose = false
) {
  const networkName = await hre.network.name;
  try {
    const fileData = fs.readFileSync(
      `artifacts/contracts/deployed/${networkName}/${contractName}_deployed.json`,
      { encoding: "utf8", flag: "r" }
    );
    const deployments = JSON.parse(fileData);
    const { contractAddress, blockNumber, txHash } =
      deployments[deployments.length - 1];
    if (verbose) {
      console.log(
        `Found ${contractName} at: ${utils.colAddrContract(contractAddress)}`
      );
    }
    const contract = await hre.ethers.getContractAt(
      contractName,
      contractAddress
    );
    contract.deployment = { txHash, blockNumber };
    return contract;
  } catch (e) {
    console.error(e);
    console.log("No deployment was found");
  }
};
