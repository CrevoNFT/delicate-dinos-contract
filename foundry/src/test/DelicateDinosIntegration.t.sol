// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "./DelicateDinosBaseIntegration.t.sol";

contract DelicateDinosIntegrationTest is DelicateDinosBaseIntegrationTest {
  function setUp() internal {
    init();
  }

  function testTest() external {
    assertTrue(true);
  }
}