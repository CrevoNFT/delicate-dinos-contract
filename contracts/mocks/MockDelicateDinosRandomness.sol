/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinosRandomness.sol";

contract MockDelicateDinosRandomness is DelicateDinosRandomness {
  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee
  ) DelicateDinosRandomness(
    _vrfCoordinator,
    _link,
    _keyHash,
    _fee
  ) {}
}