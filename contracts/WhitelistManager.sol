
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistManager {
  bytes32 public merkleRoot; // replace
  uint8 public round = 0;

  mapping(uint8 => mapping(address => bool)) public whitelistClaimed;

  function resetWhitelist(bytes32 mr) internal {
    round++;
    merkleRoot = mr;
  }

  function checkWhitelisted(bytes32[] calldata _merkleProof) internal {
    require(!whitelistClaimed[round][msg.sender], "Address already claimed");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
        MerkleProof.verify(_merkleProof, merkleRoot, leaf),
        "Invalid Merkle Proof."
    );
    whitelistClaimed[round][msg.sender] = true;
  }
}