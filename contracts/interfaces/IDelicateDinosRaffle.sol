// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDelicateDinosRaffle {

  function applyFavTokenIds(
    uint16[] calldata favouredTokenIds,
    uint8 favourFactor,
    uint256 supply
  ) external;

  
  function performLotteryDrop(uint256 randomness, uint256 numberMaxMintable) external;
}