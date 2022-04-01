/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinos.sol";

contract MockDelicateDinos is DelicateDinos {
    constructor(address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) DelicateDinos(_vrfCoordinator, _link, _keyHash, _fee) {}

    function mintFive(address account) external {
        
    }

}