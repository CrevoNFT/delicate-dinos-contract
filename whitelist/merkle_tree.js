const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")
const fs = require("fs")

module.exports = (verbose = false) => {
  let whitelistAddresses
  console.log("")
  try {
    const fileData = fs.readFileSync(`whitelist/whitelist.json`, { encoding: "utf8", flag: "r" })
    whitelistAddresses = JSON.parse(fileData)
    console.log(whitelistAddresses.length, " addresses in Whitelist")
  } catch (e) {
    console.error(e)
  }

  // 3. Create a new array of `leafNodes` by hashing all indexes of the `whitelistAddresses`
  // using `keccak256`. Then creates a Merkle Tree object using keccak256 as the algorithm.
  //
  // The leaves, merkleTree, and rootHash are all PRE-DETERMINED prior to whitelist claim
  const leafNodes = whitelistAddresses.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

  // 4. Get root hash of the `merkleeTree` in hexadecimal format (0x)
  // Print out the Entire Merkle Tree.
  const rootHash = merkleTree.getRoot()
  if (verbose) console.log("Whitelist Merkle Tree\n", merkleTree.toString())
  console.log("")
  console.log("=== Root Hash Buffer === ", rootHash)
  console.log("")
  console.log("=== Root Hash Hex String === ", rootHash.toString("hex"))
  console.log("")

  // ***** ***** ***** ***** ***** ***** ***** ***** //

  // ✅ Positive verification of address
  const claimingAddress = keccak256(whitelistAddresses[0])

  // `getHexProof` returns the neighbour leaf and all parent nodes hashes that will
  // be required to derive the Merkle Trees root hash.
  const hexProof = merkleTree.getHexProof(claimingAddress)
  // console.log("HEX PROOF for address 0: ", hexProof)

  // ✅ : Verify is claiming address is in the merkle tree or not.
  const verify = merkleTree.verify(hexProof, claimingAddress, rootHash)
  // console.log("Address 0 verification: ", verify)

  return rootHash
}
