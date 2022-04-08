// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDelicateDinosRandomness {
  function initMaster() external;
  function withdrawLink() external;
  /// @notice request for a randomness seed to use in the drop lottery
  function requestForDrop() external;
  /// @notice initiate request for a random number
  function getRandomNumber() external returns (bytes32 requestId);
  /// @notice request for a randomness seed to use in the impact simpulation
  function requestForImpact() external;
  function expandRandom(uint256 randomValue, uint256 n) external pure returns (uint256[] memory expandedValues);
}