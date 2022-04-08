// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDelicateDinos is IERC721 {
    function setDinoUpTokenAddress(address _contractAddress) external;

    function setUpgraderContract(address _upgraderContract) external;

    function withdraw() external;

    function supply() external returns (uint256);

    function startWhitelistMint(bytes32 merkleRoot, uint256 _fee) external;

    function startPublicSale(uint256 _fee) external;

    function startDropClaim() external;

    function stopMint(uint256 saleStateId) external;

    function setFee(uint256 _fee) external;

    function mintDinoWhitelisted(address addr, string memory name, bytes32[] calldata proof) external payable;

    function mintDinoPublicSale(address addr, string memory name) external payable;

    function mintDinoClaimed(uint256 tokenId, string memory name) external;

    function updateArtwork(uint256 tokenId, string memory newBaseUri) external;
    
    function getTraits(uint256 tokenId) external view returns(uint256, string memory);

    function updateTraits(uint256 tokenId, uint256 length, string memory name) external;

    function tokenIdHasArtwork(uint256 tokenId) external view returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintToOwnerOf(uint256 originTokenId, uint256 idx) external;

    function dropFinished() external;
}