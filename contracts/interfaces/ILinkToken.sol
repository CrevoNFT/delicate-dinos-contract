// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILinkToken {
 function transfer(address to, uint256 amount) external returns (bool);
 function balanceOf(address account) external returns (uint256);
} 