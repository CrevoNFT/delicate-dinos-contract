/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DelicateDinosMinter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MockDelicateDinosMinter is DelicateDinosMinter {
    constructor(address _delicateDinos) DelicateDinosMinter(_delicateDinos) {}

    function isWhitelisted(address a, bytes32 merkleRoot, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(a));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
}