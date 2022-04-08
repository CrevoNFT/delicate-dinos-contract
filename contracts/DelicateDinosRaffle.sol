// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDelicateDinos.sol";
import "./interfaces/IDelicateDinosRandomness.sol";

contract DelicateDinosRaffle is Ownable {
  bool internal favouredTokenIdsSet = false;
  uint256[] internal tokenIdTickets;
  mapping(uint256 => bool) public ticketIndexPicked;
  IDelicateDinosRandomness randomnessProvider;

  error MaxFavouredTokenId();

  constructor (address _randProvider) {
    randomnessProvider = IDelicateDinosRandomness(_randProvider);
  }

  /// @dev We may have to call it on batches of a few hundreds -> TODO test on mumbai how many it can handle
  /// @dev assume favouredTokenIds are sorted in ascending order and have no duplicates
  /// @param favouredTokenIds The ones that get several tickets in the lottery
  /// @param favourFactor How many tickets a favoured tokenId gets
  /// @param supply The total number of minted tokens
  function applyFavTokenIds(
    uint16[] calldata favouredTokenIds,
    uint8 favourFactor,
    uint256 supply
  ) external onlyOwner {
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
    favouredTokenIdsSet = true;
  }

  /// @notice Drops nfts to lottery winners. 
  /// Winners are picked based on already available tickets. There are more tickets
  /// associated with the favoured tokenIds => those tokenIds' holders have higher chances.
  /// The lottery tickets were set in WhitelistManager.applyFavouredTokenIds.
  /// @dev Worst case O(n**2)
  /// @dev This function directly mints new dinos without dedicated vrf requests. 
  /// All the lottery functionality + the random allocation of traits happends based
  /// on the @param randomness seed.
  function performLotteryDrop(uint256 randomness, uint256 numberMaxMintable) external onlyOwner {
      uint256 numberExisting = IDelicateDinos(owner()).supply();
      uint256 numberDroppable = numberMaxMintable - numberExisting;

      uint256[] memory manySeeds = randomnessProvider.expandRandom(randomness, numberDroppable);
      
      uint256 dropCt = 0;
      while (dropCt < numberDroppable) {
          // initialize index from random seed
          uint256 idx = manySeeds[dropCt] % numberExisting + 1;
          // find first one not yet picked
          while (ticketIndexPicked[idx]) {
              idx++;
          }
          // mark pick
          ticketIndexPicked[idx] = true;
          // mint-drop
          IDelicateDinos(owner()).mintToOwnerOf(tokenIdTickets[idx], manySeeds[dropCt]); // reuse random number
          dropCt++;
      }
      IDelicateDinos(owner()).dropFinished();
    }
}