// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./WhitelistManager.sol"; 
import "./libs/DelicateDinosMetadata.sol";


/**
@notice A collection of randomly generated Dinosaurs
 *
 * All collection items receive their traits at mint time.
 * Traits are generated randomly via chainlink VRF.
 * The actual artwork is only generated after minting, based on the traits.
 * 
 * We use placeholder metadata for collection items that don't have metadata yet.
 */
contract DelicateDinos is Ownable, VRFConsumerBase, ERC721, WhitelistManager, ReentrancyGuard {

    // =========== Randomness ============= //
    bytes32 internal keyHash; 
    uint256 internal vrfFee;

    event ReturnedRandomness(uint256 randomNumber);

    struct MintRequest {
        address to;
        string name;
        uint256 tokenId;
    }
    mapping(bytes32 => MintRequest) mintRequest;

    // =========== Delicate Dino ============ //

    uint256 public constant NUMBER_MAX_DINOS = 1824;

    struct Dino {
        uint256 length;
        string name;
    }

    uint256 mintIndex; // inc on mint
    mapping(uint256 => Dino) public tokenIdToDino;
    mapping(uint256 => bool) public tokenIdHasArtwork;
    mapping(uint256 => bool) public tokenIdCanClaim;
    bytes32 lotteryRequestId;

    string private _ourBaseURI;
    string constant PLACEHOLDER_IMAGE_URL = "ipfs://QmXWbz1EwJvg4u4rDXB3iS33UBk1kL4zyTRiQrda8Hic9D";

    event ArtworkSet(uint256 tokenId);

    enum MintMode {
        NOT_SET,
        WHITE_LIST,
        PUBLIC_SALE,
        DROP_CLAIM
    }

    MintMode public mintMode;
    uint256 public mintFee = 0;
    uint256 public lastDecoratedTokenId;

    address public upgraderContract;

    // ----------- errors
    
    error WithdrawFailed();
    error NoWhitelistMint();
    error NoPublicSale();
    error WrongMintFee();
    error NotOwnerOfBaseToken();
    error NothingToClaimForTokenId();
    error OnlyUpgraderContract();
    error NotEnoughLink();
    error NonExistentERC721Token();

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

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    // ====================== MINTING ==================== //

    function stopMint() public onlyOwner {
        mintMode = MintMode.NOT_SET;
    }

    function startWhitelistMint(bytes32 merkleRoot, uint256 _fee) public onlyOwner {
        resetWhitelist(merkleRoot);
        mintFee = _fee;
        mintMode = MintMode.WHITE_LIST;
    }

    function startPublicSale(uint256 _fee) public onlyOwner {
        mintFee = _fee;
        mintMode = MintMode.PUBLIC_SALE;
    }

    function startDropClaim() public onlyOwner {
        mintMode = MintMode.DROP_CLAIM;
    }

    function mintDinoWhitelisted(address addr, string memory name, bytes32[] calldata proof) public payable {
        if (mintMode != MintMode.WHITE_LIST) revert NoWhitelistMint();
        if (msg.value != mintFee) revert WrongMintFee();
        checkWhitelisted(proof);
        _requestMintDino(addr, name);
    }

    function mintDinoPublicSale(address addr, string memory name) public payable {
        if (mintMode != MintMode.PUBLIC_SALE) revert NoPublicSale();
        if (msg.value != mintFee) revert WrongMintFee();
        _requestMintDino(addr, name);
    }

    function mintDinoClaimed(uint256 tokenId, string memory name) public nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfBaseToken();
        if (!tokenIdCanClaim[tokenId]) revert NothingToClaimForTokenId();
        _requestMintDino(msg.sender, name);
    }

    function _requestMintDino(address addr, string memory name) private {
        bytes32 reqId = getRandomNumber();
        uint256 newTokenId = mintIndex + 1;
        mintRequest[reqId] = MintRequest(addr, name, newTokenId);
    }

    function _finalizeMintDino(address to, uint256 _tokenId, uint256 length, string memory name) private nonReentrant {
        _safeMint(to, _tokenId);
        // set traits
        tokenIdToDino[_tokenId] = Dino(
            length,
            name
        );
    }

    // ONLY FOR TESTS - not truly random, produces identical results if called by several callers within same block
    function requestMintDinoTest(address to, string memory name) public {
        uint256 rand = block.timestamp;
        uint256 length = rand % 10;
        uint256 tokenId = mintIndex + 1;
        _finalizeMintDino(to, tokenId, length, name);
    }

    // ============= Stats ============= // 

    function getTraits(uint256 tokenId) public view returns (uint256 length, string memory name) {
        length = tokenIdToDino[tokenId].length;
        name = tokenIdToDino[tokenId].name;
    }

    function updateTraits(uint256 tokenId, uint256 length, string memory name) external {
        if (msg.sender != upgraderContract) revert OnlyUpgraderContract();
        tokenIdToDino[tokenId].name = name;
        tokenIdToDino[tokenId].length = length;
    }

    // ============= Randomness ============== //

    /**
    * Requests randomness
    */
    function getRandomNumber() public returns (bytes32 requestId) {
        if (LINK.balanceOf(address(this)) < vrfFee) revert NotEnoughLink();
        return requestRandomness(keyHash, vrfFee);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit ReturnedRandomness(randomness);
        if (requestId == lotteryRequestId) {
            _performLotteryDrop(randomness);
        } else {
            uint256 length = randomness % 10;
            _finalizeMintDino(
                mintRequest[requestId].to, 
                mintRequest[requestId].tokenId, 
                length, 
                mintRequest[requestId].name
            );
        }
    }

    // ============= Token URI ============== //

    /// Returns the token metadata
    /// @dev Generate a data URI with the metadata json, encoded in base64
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentERC721Token();
        string memory imageUrl = tokenIdHasArtwork[tokenId] ? string(abi.encodePacked(_ourBaseURI, "/", tokenId)) : PLACEHOLDER_IMAGE_URL;
        (uint256 length, string memory name) = getTraits(tokenId);
        return DelicateDinosMetadata.dinoURI(tokenId, imageUrl, length, name);
    }   

    /// @dev keep newBaseUri as param to ensure we always remember that base uri (IPFS directory uri)
    /// changes when any of the artwork inside changes
    function updateArtwork(uint256 tokenId, string memory newBaseUri) public onlyOwner {
        tokenIdHasArtwork[tokenId] = true;
        _ourBaseURI = newBaseUri;
        emit ArtworkSet(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _ourBaseURI;
    }

    // ============= Drop Lottery ============ //

    function requestForDrop() public onlyOwner {
        lotteryRequestId = getRandomNumber();
    }

    /// @dev provides relatively distributed picks
    function _performLotteryDrop(uint256 randomness) private {
        uint256 numberExisting = mintIndex;
        uint256 numberDroppable = NUMBER_MAX_DINOS - numberExisting;
        
        uint256 idx = randomness % numberExisting + 1;
        while (numberDroppable > 0) {
            // find next index
            uint256 stepSize = (idx / 2 % numberExisting) + 1;
            uint256 nextIdx = (idx + stepSize) % numberExisting + 1;
            while (tokenIdCanClaim[nextIdx]) {
                stepSize++;
                nextIdx = (idx + stepSize) % numberExisting + 1;
            }
            // keep next index
            idx = nextIdx;

            // set claim
            tokenIdCanClaim[idx] = true;
            numberDroppable--;
        }
    }

    // =========== UPGRADES =============

    function setUpgraderContract(address _upgraderContract) external onlyOwner {
        upgraderContract = _upgraderContract;
    }
}
