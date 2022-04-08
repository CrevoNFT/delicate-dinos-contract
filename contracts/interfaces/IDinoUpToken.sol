// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDinoUpToken is IERC20 {
    function getClaimableBalance(address addr) external view returns (uint256);

    function addClaimable(address addr, uint256 amt) external;

    function claim() external;
}