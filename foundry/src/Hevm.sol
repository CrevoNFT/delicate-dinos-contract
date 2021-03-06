/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Hevm {
    // Expect a revert
    function expectRevert(bytes calldata) public virtual;

    // sets the block timestamp to x
    function warp(uint256 x) public virtual;

    // sets the block number to x
    function roll(uint256 x) public virtual;

    // sets the slot loc of contract c to val
    function store(
        address c,
        bytes32 loc,
        bytes32 val
    ) public virtual;

    function ffi(string[] calldata) external virtual returns (bytes memory);

    function prank(address) external virtual;

    function startPrank(address) external virtual;
    
    function stopPrank() external virtual;

    function assume(bool) external virtual;

}