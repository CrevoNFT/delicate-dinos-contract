// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./WhitelistManager.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * All collection items receive their traits at mint time.
 * Traits are generated randomly via chainlink VRF.
 * The actual artwork is only generated after minting, based on the traits.
 * 
 * The storage location (baseURI) of collection items will be temporarily
 * centralized until the whole collection is minted.
 */
contract DelicateDinos is Ownable, VRFConsumerBase, ERC721Pausable, IERC721Enumerable, WhitelistManager, ReentrancyGuard {

    // =========== Randomness ============= //
    bytes32 internal keyHash; 
    uint256 internal vrfFee;

    event ReturnedRandomness(uint256 randomNumber);

    struct MintRequest {
        address to;
        string name;
        uint256 mintIdx;
    }
    mapping(bytes32 => MintRequest) mintRequest;

    // =========== Delicate Dino ============ //

    struct Dino {
        uint256 length;
        string name;
    }

    Dino[] public dinos;

    // =========== Special handling of baseURI ============= //

    // once all are minted and the artwork is uploaded to IPFS,
    // this changes to the IPFS base-uri

    // string private _ourBaseURI = "https://delicate-dinos-collection/";

    // testing with BAYC
    string private _ourBaseURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";

    // ========== Enumerable ========= //

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // ====================== MINTING ==================== //

    bool public useWhitelist = false;
    uint256 public mintFee = 0;

    /**
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(
        _vrfCoordinator, 
        _link 
    ) ERC721("Delicate Dinos", "DELS")
    {
        keyHash = _keyHash;
        vrfFee = _fee;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    // ====================== MINTING ==================== //

    function activateWhitelistMode(bytes32 merkleRoot) public onlyOwner {
        resetWhitelist(merkleRoot);
        useWhitelist = true;
    }
    function deactivateWhitelistMode() public onlyOwner {
        useWhitelist = false;
    }

    function setFee(uint256 _fee) public onlyOwner {
        mintFee = _fee;
    }

    function mintDinoWhitelisted(address addr, string memory name, bytes32[] calldata proof) public payable {
        require (useWhitelist, "not in whitelist minting mode");
        require (msg.value == mintFee, "paid amount doesn't match mint fee");
        checkWhitelisted(proof);
        requestMintDino(addr, name);
    }

    function mintDinoSimple(address addr, string memory name) public payable {
        require (!useWhitelist, "whitelisted only. use function mintDinoWhitelisted()");
        require (msg.value == mintFee, "paid amount doesn't match mint fee");
        requestMintDino(addr, name);
    }

    function requestMintDino(address addr, string memory name) public {
        bytes32 reqId = getRandomNumber();
        uint256 mintIndex = totalSupply();
        mintRequest[reqId] = MintRequest(addr, name, mintIndex);
    }

    function finalizeMintDino(address to, uint256 mintIndex, uint256 length, string memory name) private {
        // set metadata length etc.
        dinos.push(Dino(
            length,
            name
        ));
        _safeMint(to, mintIndex);
    }

    // ONLY FOR TESTS - not truly random, produces identical results if called by several callers within same block
    function requestMintDinoTest(address to, string memory name) public {
        uint256 rand = block.timestamp;
        uint256 length = rand % 10;
        uint256 mintIndex = totalSupply();
        finalizeMintDino(to, mintIndex, length, name);
    }

    // ============= Randomness ============== //

    /**
    * Requests randomness
    */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, vrfFee);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit ReturnedRandomness(randomness);
        uint256 length = randomness % 10;
        finalizeMintDino(
            mintRequest[requestId].to, 
            mintRequest[requestId].mintIdx, 
            length, 
            mintRequest[requestId].name
        );
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract


    // ============= Custom Base URI ============== //    

    function _setOurBaseURI(string memory uri) public onlyOwner {
        _ourBaseURI = uri;
    }
    function _baseURI() internal view override returns (string memory) {
        return _ourBaseURI;
    }

    // ============= Pausable & Enumerable ============= //


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

}
