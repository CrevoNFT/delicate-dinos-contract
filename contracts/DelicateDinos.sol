// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhitelistManager.sol"; 
import "./interfaces/IDelicateDinosRandomness.sol"; 
import "./interfaces/IDelicateDinosRaffle.sol"; 
import "./interfaces/IDinoUpToken.sol";
import "./libs/DelicateDinosUpgrade.sol"; 
import "./libs/DelicateDinosMetadata.sol";

/**
 @title A collection of randomly generated Dinosaurs
 *
 * @notice All collection items receive their traits at mint time. Traits are generated randomly via chainlink VRF.
 * @notice The actual artwork is only generated after minting, based on the traits.
 * @notice We use placeholder metadata for collection items that don't have metadata yet.
 */
contract DelicateDinos is Ownable, ERC721 {

    IDelicateDinosRaffle public raffleContract;
    
    // =========== Randomness ============= //
    IDelicateDinosRandomness public randomnessProvider;

    struct MintRequest {
        address to;
        string[] names;
        uint256[] tokenIds;
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

    uint256 public supply; // inc on mint
    mapping(uint256 => Dino) public tokenIdToDino;
    mapping(uint256 => bool) public tokenIdHasArtwork;
    mapping(uint256 => bytes32) internal tokenIdToMintRequestId;
    
    string private _ourBaseURI;
    string public constant PLACEHOLDER_IMAGE_URL = "ipfs://QmVg9ZSr3dL8C8Qcm1C8v51xUqhQYGX4NarRkKGsJXJiLs";

    event DropFinished();
    event ArtworkSet(uint256 tokenId);
    event DinoDamaged(uint8 updatedFossilValue);

    bool renameUnlocked = false;
    mapping(uint256 => bool) public tokenIdHasRenamed;

    uint256 public lastDecoratedTokenId;


    IDinoUpToken public dinoUpToken;

    address public minterContract;

    // ----------- errors
    
    error WithdrawFailed();
    error NotTokenOwner();
    error NotOwnerOfBaseToken();
    error NothingToClaimForTokenId();
    error OnlyRandomnessProvider();
    error OnlyRaffle();
    error NotEnoughDnoUp();
    error NonExistentERC721Token();
    error RenameLocked();
    error HasRenamedAlready();
    error InsufficientAllowanceToUpgrade();
    error OnlyMinterContract();

    modifier onlyRandomnessProvider {
        if (msg.sender != address(randomnessProvider)) revert OnlyRandomnessProvider();
        _;
    }
    modifier onlyMinterContract {
        if (msg.sender != minterContract) revert OnlyMinterContract();
        _;
    }

    constructor(
        address _randomnessProvider,
        address _raffleContract,
        address _dinoUpToken
    ) ERC721("Delicate Dinos", "DELS")
    {
        randomnessProvider = IDelicateDinosRandomness(_randomnessProvider);
        raffleContract = IDelicateDinosRaffle(_raffleContract);
        dinoUpToken = IDinoUpToken(_dinoUpToken);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // ====================== MINTING ==================== //

    function setMinterContract(address _minter) public onlyOwner {
        minterContract = _minter;
    }

    /// @notice Called by minter contract to initiate minting for given account. Several Dinos can be minted at once.
    /// @param names are provided to assign to minted dinos. From this array's length we infer the number of Dinos to be minted.
    function requestMintDinos(address addr, string[] memory names) external onlyMinterContract {
        bytes32 reqId = randomnessProvider.getRandomNumber();
        uint256[] memory newTokenIds = new uint256[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            supply++;
            newTokenIds[i] = supply;
            tokenIdToMintRequestId[newTokenIds[i]] = reqId;
        }
        mintRequest[reqId] = MintRequest(addr, names, newTokenIds);
    }

    function finalizeMintDino(bytes32 requestId, uint256 randomness) external onlyRandomnessProvider {
        address to = mintRequest[requestId].to;
        uint256[] memory _tokenIds = mintRequest[requestId].tokenIds;
        string[] memory _names = mintRequest[requestId].names;
        uint256[] memory dinoSeeds = randomnessProvider.expandRandom(randomness, _names.length);
        for (uint i = 0; i < _names.length; i++) {
            uint256[] memory traitSeeds = randomnessProvider.expandRandom(dinoSeeds[i], 2);
            uint8 teethLength = uint8(traitSeeds[0] % (2**8));
            uint8 skinThickness = uint8(traitSeeds[1] % (2**8)); 
            _mintDinoWithTraits(to, _tokenIds[i], teethLength, skinThickness, _names[i]);
        }
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
        supply = supply + 1;
        uint256 newTokenId = supply;
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

    /// @notice apply favoured token IDs and initiate the lottery drop
    /// @param favouredTokenIds array of token ids which are favoured in the lottery
    /// @param favourFactor how many tickets a favoured Token Id gets in the lottery
    function startDrop(uint16[] calldata favouredTokenIds, uint8 favourFactor) external onlyOwner {
        raffleContract.applyFavTokenIds(favouredTokenIds, favourFactor, supply);
        randomnessProvider.requestForDrop();
    }

    function performLotteryDrop(uint256 randomness) external onlyRandomnessProvider {
        raffleContract.performLotteryDrop(randomness, NUMBER_MAX_DINOS);
    }

    function mintToOwnerOf(uint256 originTokenId, uint256 idx) external {
        if (msg.sender != address(raffleContract)) revert OnlyRaffle();
        _mintToLotteryWinner(ownerOf(originTokenId), idx);
    }

    function dropFinished() external {
      if (msg.sender != address(raffleContract)) revert OnlyRaffle();
      emit DropFinished();
    }

    // ================ IMPACT ================= // 

    function impact() public onlyOwner {
        randomnessProvider.requestForImpact();
    }

    function performImpact(uint256 randomness) external onlyRandomnessProvider {
        for (uint256 i = 1; i <= supply; i++) {
            uint8 damage = uint8(randomness % 100); // (worst case: 100 points out of max 255)
            tokenIdToDino[i].fossilValue -= damage;
            emit DinoDamaged(tokenIdToDino[i].fossilValue);
        }
    }
}
