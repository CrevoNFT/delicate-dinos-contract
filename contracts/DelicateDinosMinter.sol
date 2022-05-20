// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhitelistManager.sol"; 
import "./interfaces/IDelicateDinos.sol"; 
import "./interfaces/IDelicateDinosRaffle.sol"; 
import "./interfaces/IDinoUpToken.sol";
import "./libs/DelicateDinosUpgrade.sol"; 
import "./libs/DelicateDinosMetadata.sol";

/**
  @title A controller contract for minting Dinos in whitelist / public sale mode 
 */
contract DelicateDinosMinter is Ownable, WhitelistManager {
  address public dinosContract;

  error MintModeMustBeUnset();
  error NoWhitelistMint();
  error NoPublicSale();
  error PublicSaleIsOver();
  error WrongMintFee();
  error SetupWithZeroMaxMint();
  error SetupWithInitialPriceBelowMinPrice();
  error MintLimit();
  error NumberToMintAndNamesMismatch();
  
  enum MintMode {
      NOT_SET,
      WHITE_LIST,
      PUBLIC_SALE
  }

  MintMode public mintMode;
  uint256 public mintFee; // fee to mint 1 Dino
  uint256 public maxMint; // max dinos that a whitelisted user can mint

  mapping(address => uint256) public mintedInSale; // number of dinos minted by account during public sale

  uint256 public initialSaleTime; // timestamp 
  uint256 public initialSalePrice; // MATIC
  uint256 public salePriceDecrement; // MATIC
  uint256 public minSalePrice; // MATIC
  uint256 public saleTierDuration; // seconds

  constructor(address _dinosContract) {
    dinosContract = _dinosContract;
  }

  function stopMint() public onlyOwner {
      mintMode = MintMode.NOT_SET;
  }

  function startWhitelistMint(bytes32 merkleRoot, uint256 _fee, uint256 _maxMint) public onlyOwner {
    if (mintMode != MintMode.NOT_SET) revert MintModeMustBeUnset();
    if (_maxMint == 0) revert SetupWithZeroMaxMint();
    resetWhitelist(merkleRoot);
    mintFee = _fee;
    maxMint = _maxMint;
    mintMode = MintMode.WHITE_LIST;
  }

  /// @notice Start the public sale. When price has gotten below min price, no more sales are possible.
  /// @param _initialSalePrice Sale begins at this inital price.
  /// @param _minSalePrice Sale ends when below this price.
  /// @param _salePriceDecrement Sale price decreases by this value once per tier.
  /// @param _saleTierDurationInHours Duration of a tier interval in HOURS
  /// @param _maxMint Maximum mintable Dinos per call
  function startPublicSale(uint256 _initialSalePrice, uint256 _minSalePrice, uint256 _salePriceDecrement, uint256 _saleTierDurationInHours, uint256 _maxMint) public onlyOwner {
    if (mintMode != MintMode.NOT_SET) revert MintModeMustBeUnset();
    if (_maxMint == 0) revert SetupWithZeroMaxMint();
    if (_initialSalePrice < _minSalePrice) revert SetupWithInitialPriceBelowMinPrice();
    initialSalePrice = _initialSalePrice;
    minSalePrice = _minSalePrice;
    salePriceDecrement = _salePriceDecrement;
    saleTierDuration = _saleTierDurationInHours * 1 hours;
    maxMint = _maxMint;
    initialSaleTime = block.timestamp;
    mintMode = MintMode.PUBLIC_SALE;
  }

  /// @notice Mints given number of dinos to whitelisted account during whitelist round.
  /// @notice For any whitelist round, this function can only be called once per account.
  /// @param addr whitelisted account to mint to (future owner of Dinos)
  /// @param numberOfDinos how many dinos to mint
  function mintDinoWhitelisted(address addr, string[] memory names, bytes32[] calldata proof, uint256 numberOfDinos) public payable {
    if (mintMode != MintMode.WHITE_LIST) revert NoWhitelistMint();
    if (msg.value != mintFee) revert WrongMintFee();
    if (numberOfDinos > maxMint) revert MintLimit();
    if (names.length != numberOfDinos) revert NumberToMintAndNamesMismatch();
    checkWhitelisted(addr, proof);
    IDelicateDinos(dinosContract).requestMintDinos(addr, names);
  }

  /// @notice Mint price given the time passed since it started
  function currentSalePrice() public returns(uint256) {
    if (mintMode != MintMode.PUBLIC_SALE) revert NoPublicSale();
    uint256 intervalsPassed = (block.timestamp - initialSaleTime) / saleTierDuration;
    uint256 priceDecrement = intervalsPassed * salePriceDecrement;
    if (initialSalePrice - minSalePrice < priceDecrement) revert PublicSaleIsOver();
    return initialSalePrice - priceDecrement;
  }

  /// @notice Mint given number of dinos during public sale.
  /// @param addr whitelisted account to mint to (future owner of Dinos)
  /// @param numberOfDinos how many dinos to mint with this call
  function mintDinoPublicSale(address addr, string[] memory names, uint256 numberOfDinos) public payable {
    if (names.length != numberOfDinos) revert NumberToMintAndNamesMismatch();
    if (mintMode != MintMode.PUBLIC_SALE) revert NoPublicSale();
    uint256 salePrice = currentSalePrice(); // reverts if sale is over
    if (msg.value != salePrice * numberOfDinos) revert WrongMintFee();
    if (numberOfDinos + mintedInSale[addr] > maxMint) revert MintLimit();
    mintedInSale[addr] += numberOfDinos;
    IDelicateDinos(dinosContract).requestMintDinos(addr, names);
  }

  /// @notice Convenience function for frontend
  function mintsLeftInCurrentRound(address addr) public returns(uint256) {
    if (mintMode == MintMode.NOT_SET) return 0;
    return maxMint - mintedInSale[addr];
  }

}