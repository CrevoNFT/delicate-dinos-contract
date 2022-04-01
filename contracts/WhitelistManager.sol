
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistManager {
  bytes32 public merkleRoot; // replace
  uint8 public round = 0;

  mapping(uint8 => mapping(address => bool)) public whitelistClaimed;

  error AlreadyClaimed();
  error InvalidProof();

  function resetWhitelist(bytes32 mr) internal {
    round++;
    merkleRoot = mr;
  }

  function hasClaimed(address claimer) public view returns (bool) {
    return whitelistClaimed[round][claimer];
  }

  function checkWhitelisted(address claimer, bytes32[] calldata _merkleProof) internal {
    if (whitelistClaimed[round][claimer]) revert AlreadyClaimed();
    bytes32 leaf = keccak256(abi.encodePacked(claimer));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();
    whitelistClaimed[round][claimer] = true;
  }
}