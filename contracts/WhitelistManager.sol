
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistManager {
  bytes32 public merkleRoot; // replace
  uint8 public round = 0;

  mapping(uint8 => mapping(address => bool)) public whitelistClaimed;
  uint256[] internal tokenIdTickets;

  error AlreadyClaimed();
  error InvalidProof();
  error MaxFavouredTokenId();

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

  /// @dev We may have to call it on batches of a few hundreds -> TODO test on mumbai how many it can handle
  /// @dev assume favouredTokenIds are sorted in ascending order and have no duplicates
  /// @param favouredTokenIds The ones that get several tickets in the lottery
  /// @param favourFactor How many tickets a favoured tokenId gets
  /// @param supply The total number of minted tokens
  function applyFavouredTokenIds(uint16[] calldata favouredTokenIds, uint8 favourFactor, uint256 supply) external virtual {
    if (uint256(favouredTokenIds[favouredTokenIds.length - 1]) > supply) revert MaxFavouredTokenId();

    uint256 tokenId = 1;
    uint256 idxFavoured = 0;

    while (idxFavoured < favouredTokenIds.length) {
      if (favouredTokenIds[idxFavoured] == tokenId) {
        // match - give several tickets
        for (uint8 j = 0; j < favourFactor; j++) {
          tokenIdTickets.push(tokenId);
          idxFavoured++;
        }
      } else {
        // no match - give one ticket
        tokenIdTickets.push(tokenId);
      }
      tokenId++;
    } 
  }
}