// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library DelicateDinosUpgrade {
  function requiredTokenAmount(
    uint8 currentTeethLength,
    uint8 currentSkinThickness,
    uint8 teethLengthDelta,
    uint8 skinThicknessDelta
  ) external pure returns (uint256){
    return 1*1e18;
  }
}