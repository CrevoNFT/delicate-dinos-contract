/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinos.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MockDelicateDinos is DelicateDinos {
    constructor(address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _dinoUpToken
    ) DelicateDinos(_vrfCoordinator, _link, _keyHash, _fee, _dinoUpToken) {}


    function isWhitelisted(address a, bytes32 merkleRoot, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(a));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

}