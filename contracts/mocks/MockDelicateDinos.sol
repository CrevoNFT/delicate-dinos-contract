/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinos.sol";

contract MockDelicateDinos is DelicateDinos {
    constructor(address _randomnessProvider,
        address _raffleContract,
        address _dinoUpToken
    ) DelicateDinos(_randomnessProvider, _raffleContract, _dinoUpToken) {}

    function getTokenIdToMintRequestId(uint256 tokenId) external returns(bytes32) {
        return tokenIdToMintRequestId[tokenId];
    }

}