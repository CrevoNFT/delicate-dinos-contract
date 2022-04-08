/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinosRaffle.sol";

contract MockDelicateDinosRaffle is DelicateDinosRaffle {
  constructor(
    address _randProvider
  ) DelicateDinosRaffle(
    _randProvider
  ) {}
}