// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhitelistManager.sol"; 
import "./DelicateDinosRandomness.sol"; 
import "./libs/DelicateDinosUpgrade.sol"; 
import "./libs/DelicateDinosMetadata.sol";
import "./DinoUpToken.sol";
import "./interfaces/ILinkToken.sol";

/**
@notice A collection of randomly generated Dinosaurs
 *
 * All collection items receive their traits at mint time.
 * Traits are generated randomly via chainlink VRF.
 * The actual artwork is only generated after minting, based on the traits.
 * 
 * We use placeholder metadata for collection items that don't have metadata yet.
 */
contract DelicateDinos is Ownable, ERC721, WhitelistManager, ReentrancyGuard {

    // =========== Randomness ============= //
    DelicateDinosRandomness public randomnessProvider;
    address public linkToken;

    struct MintRequest {
        address to;
        string name;
        uint256 tokenId;
    }
    mapping(bytes32 => MintRequest) mintRequest;

    // =========== Delicate Dino ============ //

    uint256 public constant NUMBER_MAX_DINOS = 1824;

    struct Dino {
        string name;
        uint8 fossilValue;
        uint8 teethLength;
        uint8 skinThickness;
    }

    uint256 public mintIndex; // inc on mint
    mapping(uint256 => Dino) public tokenIdToDino;
    mapping(uint256 => bool) public tokenIdHasArtwork;
    mapping(uint256 => bytes32) public tokenIdToMintRequestId;
    
    mapping(uint256 => bool) public ticketIndexPicked;
    
    string private _ourBaseURI;
    string public constant PLACEHOLDER_IMAGE_URL = "ipfs://QmVg9ZSr3dL8C8Qcm1C8v51xUqhQYGX4NarRkKGsJXJiLs";

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

    bool renameUnlocked = false;
    mapping(uint256 => bool) public tokenIdHasRenamed;

    DinoUpToken public dinoUpToken;

    // ----------- errors
    
    error WithdrawFailed();
    error NoWhitelistMint();
    error NoPublicSale();
    error WrongMintFee();
    error NotTokenOwner();
    error NotOwnerOfBaseToken();
    error NothingToClaimForTokenId();
    error OnlyRandomnessProvider();
    error NotEnoughDnoUp();
    error NonExistentERC721Token();
    error RenameLocked();
    error HasRenamedAlready();
    error InsufficientAllowanceToUpgrade();

    modifier onlyRandomnessProvider {
        if (msg.sender != address(randomnessProvider)) revert OnlyRandomnessProvider();
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _dinoUpToken
    ) ERC721("Delicate Dinos", "DELS")
    {
        randomnessProvider = new DelicateDinosRandomness(
            _vrfCoordinator,
            _link,
            _keyHash,
            _fee
        );
        dinoUpToken = DinoUpToken(_dinoUpToken);
        linkToken = _link;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawLink() public onlyOwner {
        randomnessProvider.withdrawLink();
        ILinkToken(linkToken).transfer(msg.sender, ILinkToken(linkToken).balanceOf(address(this)));
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
        checkWhitelisted(addr, proof);
        _requestMintDino(addr, name);
    }

    function mintDinoPublicSale(address addr, string memory name) public payable {
        if (mintMode != MintMode.PUBLIC_SALE) revert NoPublicSale();
        if (msg.value != mintFee) revert WrongMintFee();
        _requestMintDino(addr, name);
    }

    function _requestMintDino(address addr, string memory name) private {
        bytes32 reqId = randomnessProvider.getRandomNumber();
        mintIndex = mintIndex + 1;
        uint256 newTokenId = mintIndex;
        mintRequest[reqId] = MintRequest(addr, name, newTokenId);
        tokenIdToMintRequestId[newTokenId] = reqId;
    }

    function finalizeMintDino(bytes32 requestId, uint256 randomness) external nonReentrant onlyRandomnessProvider {
        address to = mintRequest[requestId].to;
        uint256 _tokenId = mintRequest[requestId].tokenId;
        string memory name = mintRequest[requestId].name;
        uint256[] memory twoValues = randomnessProvider.expandRandom(randomness, 2);
        uint8 teethLength = uint8(twoValues[0] % (2**8));
        uint8 skinThickness = uint8(twoValues[1] % (2**8)); 
        _mintDinoWithTraits(to, _tokenId, teethLength, skinThickness, name);
    }

    function _mintDinoWithTraits(
        address to,
        uint256 tokenId,
        uint8 teethLength,
        uint8 skinThickness,
        string memory name
    ) private {
        _safeMint(to, tokenId);
        // set traits
        uint8 fullFossilValue = 2**8-1; // max at birth
        tokenIdToDino[tokenId] = Dino(
            name,
            fullFossilValue,
            teethLength,
            skinThickness
        );
    }

    function _mintToLotteryWinner(address winner, uint256 randomness) private {
        mintIndex = mintIndex + 1;
        uint256 newTokenId = mintIndex;
        uint256[] memory twoValues = randomnessProvider.expandRandom(randomness, 2);
        uint8 teethLength = uint8(twoValues[0] % (2**8));
        uint8 skinThickness = uint8(twoValues[1] % (2**8)); 
        _mintDinoWithTraits(winner, newTokenId, teethLength, skinThickness, "");
    }

    // ============= Traits ============= // 

    function getTraits(uint256 tokenId) public view returns (uint8 teethLength, uint8 skinThickness, string memory name) {
        teethLength = tokenIdToDino[tokenId].teethLength;
        skinThickness = tokenIdToDino[tokenId].teethLength;
        string memory n = tokenIdToDino[tokenId].name;
        name = n;
    }

    function upgradeTraits(
        uint256 tokenId, uint8 teethLengthDelta, uint8 skinThicknessDelta, uint256 dnoUpTokenAmount
    ) public {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (dinoUpToken.allowance(msg.sender, address(this)) < dnoUpTokenAmount) revert InsufficientAllowanceToUpgrade();

        uint256 requiredTokenAmount = DelicateDinosUpgrade.requiredTokenAmount(
            tokenIdToDino[tokenId].teethLength,
            tokenIdToDino[tokenId].skinThickness,
            teethLengthDelta,
            skinThicknessDelta
        );
        bool sufficientDnoUp = dnoUpTokenAmount >= requiredTokenAmount; 
        if (!sufficientDnoUp) revert NotEnoughDnoUp();

        tokenIdToDino[tokenId].teethLength += teethLengthDelta;
        tokenIdToDino[tokenId].skinThickness += skinThicknessDelta;
    }

    function setName(uint256 tokenId, string memory _name) public {
        if (!renameUnlocked) revert RenameLocked();
        if (tokenIdHasRenamed[tokenId]) revert HasRenamedAlready();
        tokenIdToDino[tokenId].name = _name;
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
        (uint8 teethLength, uint8 skinThickness, string memory name) = getTraits(tokenId);
        return DelicateDinosMetadata.dinoURI(tokenId, imageUrl, teethLength, skinThickness, name);
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

    function applyFavouredTokenIds(
        uint16[] calldata favouredTokenIds,
        uint8 favourFactor,
        uint256 supply
    ) external override onlyRandomnessProvider {
        this.applyFavouredTokenIds(favouredTokenIds, favourFactor, supply);
    }

    /// @notice Drops nfts to lottery winners. 
    /// Winners are picked based on already available tickets. There are more tickets
    /// associated with the favoured tokenIds => those tokenIds' holders have higher chances.
    /// The lottery tickets were set in WhitelistManager.applyFavouredTokenIds.
    /// @dev Worst case O(n**2)
    /// @dev This function directly mints new dinos without dedicated vrf requests. 
    /// All the lottery functionality + the random allocation of traits happends based
    /// on the @param randomness seed.
    function performLotteryDrop(uint256 randomness) external onlyRandomnessProvider {
        uint256 numberExisting = mintIndex;
        uint256 numberDroppable = NUMBER_MAX_DINOS - numberExisting;

        uint256[] memory manySeeds = randomnessProvider.expandRandom(randomness, numberDroppable);
        
        uint256 dropCt = 0;
        while (dropCt < numberDroppable) {
            // initialize index from random seed
            uint256 idx = manySeeds[dropCt] % numberExisting + 1;
            // find first one not yet picked
            while (ticketIndexPicked[idx]) {
                idx++;
            }
            // mark pick
            ticketIndexPicked[idx] = true;
            // mint-drop
            address winner = ownerOf(tokenIdTickets[idx]);
            _mintToLotteryWinner(winner, manySeeds[dropCt]); // reuse random number
            dropCt++;
        }
    }
}
