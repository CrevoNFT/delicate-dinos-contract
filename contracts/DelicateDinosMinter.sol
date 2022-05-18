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

  error NoWhitelistMint();
  error NoPublicSale();
  error WrongMintFee();
  error SetupWithZeroMaxMint();
  error MintLimit();
  error NumberToMintAndNamesMismatch();
  
  enum MintMode {
      NOT_SET,
      WHITE_LIST,
      PUBLIC_SALE
  }

  MintMode public mintMode;
  uint256 public mintFee = 0; // fee to mint 1 Dino
  uint256 public maxMint = 0; // max dinos that a whitelisted user can mint

  mapping(address => uint256) mintedInSale; // number of dinos minted by account during public sale

  constructor(address _dinosContract) {
    dinosContract = _dinosContract;
  }

  function stopMint() public onlyOwner {
      mintMode = MintMode.NOT_SET;
  }

  function startWhitelistMint(bytes32 merkleRoot, uint256 _fee, uint256 _maxMint) public onlyOwner {
    if (_maxMint == 0) revert SetupWithZeroMaxMint();
    resetWhitelist(merkleRoot);
    mintFee = _fee;
    maxMint = _maxMint;
    mintMode = MintMode.WHITE_LIST;
  }

  function startPublicSale(uint256 _fee, uint256 _maxMint) public onlyOwner {
    if (_maxMint == 0) revert SetupWithZeroMaxMint();
    mintFee = _fee;
    maxMint = _maxMint;
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

  /// @notice Mint given number of dinos during public sale.
  /// @param addr whitelisted account to mint to (future owner of Dinos)
  /// @param numberOfDinos how many dinos to mint with this call
  function mintDinoPublicSale(address addr, string[] memory names, uint256 numberOfDinos) public payable {
    if (mintMode != MintMode.PUBLIC_SALE) revert NoPublicSale();
    if (msg.value != mintFee) revert WrongMintFee();
    if (numberOfDinos + mintedInSale[addr] > maxMint) revert MintLimit();
    if (names.length != numberOfDinos) revert NumberToMintAndNamesMismatch();
    mintedInSale[addr] += numberOfDinos;
    IDelicateDinos(dinosContract).requestMintDinos(addr, names);
  }

  /// @notice Convenience function for frontend
  function mintsLeftInCurrentRound(address addr) public returns(uint256) {
    if (mintMode == MintMode.NOT_SET) return 0;
    return maxMint - mintedInSale[addr];
  }

}