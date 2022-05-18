// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "./DelicateDinosBaseIntegration.t.sol";
import "../contracts/DelicateDinos.sol";
import "../contracts/WhitelistManager.sol";

contract DelicateDinosIntegrationTest is DelicateDinosBaseIntegrationTest {

  uint256 constant RANDOM_NUMBER = 12312412121357;  
  bytes32[] merkleProof;
  bytes32 constant MERKLE_ROOT = bytes32(0xe99abc00c34b105cee0fb029ef32528d15ac5ed72d3fe510d675f3cc599de199);
  uint256 constant DEFAULT_MINT_FEE = 1e18;


  string[] oneName;
  string[] oneName2;
  string[] twoNames;
  string[] threeNames;

  function setUp() external {
    init();

    oneName.push("Firsty");
    oneName2.push("Secondy");
    twoNames.push("Firsty");
    twoNames.push("Secondy");
    threeNames.push("Firsty");
    threeNames.push("Secondy");
    threeNames.push("Thirdy");

    merkleProof.push(bytes32(0x702d0f86c1baf15ac2b8aae489113b59d27419b751fbf7da0ef0bae4688abc7a));
    merkleProof.push(bytes32(0xb159efe4c3ee94e91cc5740b9dbb26fc5ef48a14b53ad84d591d0eb3d65891ab));
  }

  // ============ WHITELISTED MINT ============= //

  /// @notice cannot open whitelist mint round with zero maxmint
  function testCannotInitWhitelistWithZeroMaxMint() external {
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.SetupWithZeroMaxMint.selector));
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, 0, 0);
  }

  function testCanMintWhitelisted() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1);
    assertTrue(delicateDinos.supply() == 0);
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);
    assertTrue(delicateDinos.supply() == 1);
    bytes32 requestId = delicateDinos.getTokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinos.ownerOf(1) == address(this));
    emit log_string(delicateDinos.tokenURI(1));
  }

  function testCanMintMultipleAtOnceWhitelisted() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 2);
    assertTrue(delicateDinos.supply() == 0);
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), twoNames, merkleProof, 2);
    assertTrue(delicateDinos.supply() == 2);
    bytes32 requestId = delicateDinos.getTokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinos.ownerOf(1) == address(this));
    assertTrue(delicateDinos.ownerOf(2) == address(this));
    assertTrue(delicateDinos.supply() == 2);
  }

  function testWhitelistMintNamesNumberMismatch() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 2);
    assertTrue(oneName.length == 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NumberToMintAndNamesMismatch.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 2);
  }

  function testCannotMintAboveMaxWhitelisted() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 2);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.MintLimit.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), twoNames, merkleProof, 3);
  }

  /// @notice Whitelisted account can receive multiple minted tokens, but all must be minted at once
  function testCannotMintTwiceWhitelisted() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 2); // we allow for max 2, but only mint 1
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);
    bytes32 requestId = delicateDinos.getTokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinosMinter.hasClaimed(address(this)));
    HEVM.expectRevert(abi.encodeWithSelector(WhitelistManager.AlreadyClaimed.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName2, merkleProof, 1);
  }

  function testCannotMintNonWhitelisted(address randomAddr) external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1);
    assertTrue(delicateDinos.supply() == 0);
    HEVM.expectRevert(abi.encodeWithSelector(WhitelistManager.InvalidProof.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(randomAddr, oneName, merkleProof, 1);
  }

  function testCannotMintWrongFeeWhitelisted(uint256 randomFee) external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1); // we allow for max 2, but only mint 1
    HEVM.assume(randomFee < DEFAULT_MINT_FEE);
    assertTrue(delicateDinos.supply() == 0);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.WrongMintFee.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: randomFee}(address(this), oneName, merkleProof, 1);
  }

  function testCanMintWhitelistedOnlyInWhitelistedMode() external {
    // initial state
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);

    delicateDinosMinter.startPublicSale(DEFAULT_MINT_FEE, 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);

    delicateDinosMinter.stopMint();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);
  }

  // ================ MINT PUBLIC SALE ================= // 

  /// @notice cannot open public sale with zero maxmint
  function testCannotInitPublicSaleWithZeroMaxMint() external {
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.SetupWithZeroMaxMint.selector));
    delicateDinosMinter.startPublicSale(DEFAULT_MINT_FEE, 0);
  }

  function testPublicSaleMintNamesNumberMismatch() external {
    delicateDinosMinter.startPublicSale(DEFAULT_MINT_FEE, 2);
    assertTrue(oneName.length == 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NumberToMintAndNamesMismatch.selector));
    delicateDinosMinter.mintDinoPublicSale{value: DEFAULT_MINT_FEE}(address(this), oneName, 2);
  }

  function testCanMintPublicSaleOnlyInPublicSaleMode() external {
    // initial state
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoPublicSale.selector));
    delicateDinosMinter.mintDinoPublicSale{value: DEFAULT_MINT_FEE}(address(this), oneName, 1);

    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoPublicSale.selector));
    delicateDinosMinter.mintDinoPublicSale{value: DEFAULT_MINT_FEE}(address(this), oneName, 1);
    
    delicateDinosMinter.stopMint();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoPublicSale.selector));
    delicateDinosMinter.mintDinoPublicSale{value: DEFAULT_MINT_FEE}(address(this), oneName, 1);
  }

  // TODO can mint public sale

  // TODO can mint repeatedly during public sale

  // TODO cannot mint more than maxLimit at once
  
  // TODO Cannot mint more than maxLimit overall

  // TODO cannot mint with wrong fee

  

  // ================ MINT DROP ================= // 

  // TODO drop lottery - only while no whitelist or public sale is happening

  // TODO drop lottery - new tokens are indeed minted
  
  // TODO drop lottery - fuzz - higher chances for favoured tokenIds



  // =============== ARTWORK & STATS ================ // 

  // TODO random token stats in correct range (0..255)

  // TODO name is set correctly

  // TODO tokenURI displays correctly if no name is set

  // TODO placeholder artwork (tokenURI with placeholder)

  // TODO artwork can be updated (baseuri changes, tokenURI correct)


  // =============== UPGRADER =================== // 

  // TODO can upgrade features

  // TODO upgrade fails when insufficient DNOUP paid

  // TODO upgrade fails when not the owner of the token

  // =============== RENAMING ================== //

  // TODO can rename

  // TODO can only rename once

  // TODO cannot rename if locked


}