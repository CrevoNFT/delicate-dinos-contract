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

  function setUp() external {
    init();

    merkleProof.push(bytes32(0x702d0f86c1baf15ac2b8aae489113b59d27419b751fbf7da0ef0bae4688abc7a));
    merkleProof.push(bytes32(0xb159efe4c3ee94e91cc5740b9dbb26fc5ef48a14b53ad84d591d0eb3d65891ab));
  }

  // ============ WHITELISTED MINT ============= //

  function testCanMintWhitelisted() external {
    uint256 _fee = 1e18;
    delicateDinos.startWhitelistMint(MERKLE_ROOT, _fee);
    assertTrue(delicateDinos.mintIndex() == 0);
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);
    assertTrue(delicateDinos.mintIndex() == 1);
    bytes32 requestId = delicateDinos.tokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinos.ownerOf(1) == address(this));
  }

  function testCannotMintTwiceWhitelisted() external {
    uint256 _fee = 1e18;
    delicateDinos.startWhitelistMint(MERKLE_ROOT, _fee);
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);
    bytes32 requestId = delicateDinos.tokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinos.hasClaimed(address(this)));
    HEVM.expectRevert(abi.encodeWithSelector(WhitelistManager.AlreadyClaimed.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Secondy", merkleProof);
  }

  function testCannotMintNonWhitelisted(address randomAddr) external {
    uint256 _fee = 1e18;
    delicateDinos.startWhitelistMint(MERKLE_ROOT, _fee);
    assertTrue(delicateDinos.mintIndex() == 0);
    HEVM.expectRevert(abi.encodeWithSelector(WhitelistManager.InvalidProof.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(randomAddr, "Firsty", merkleProof);
  }

  function testCannotMintWrongFeeWhitelisted(uint256 randomFee) external {
    uint256 _fee = 1e18;
    HEVM.assume(randomFee < _fee);
    delicateDinos.startWhitelistMint(MERKLE_ROOT, _fee);
    assertTrue(delicateDinos.mintIndex() == 0);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.WrongMintFee.selector));
    delicateDinos.mintDinoWhitelisted{value: randomFee}(address(this), "Firsty", merkleProof);
  }

  function testCanMintWhitelistedOnlyInWhitelistedMode() external {
    uint256 _fee = 1e18;

    // initial state
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoWhitelistMint.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);

    delicateDinos.startPublicSale(_fee);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoWhitelistMint.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);

    delicateDinos.startDropClaim();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoWhitelistMint.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);

    delicateDinos.stopMint();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoWhitelistMint.selector));
    delicateDinos.mintDinoWhitelisted{value: _fee}(address(this), "Firsty", merkleProof);
  }

  // ================ MINT PUBLIC SALE ================= // 

  // TODO can mint public sale

  // TODO cannot mint with wrong fee

  function testCanMintPublicSaleOnlyInPublicSaleMode() external {
    uint256 _fee = 1e18;

    // initial state
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoPublicSale.selector));
    delicateDinos.mintDinoPublicSale{value: _fee}(address(this), "Firsty");

    delicateDinos.startWhitelistMint(MERKLE_ROOT, _fee);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoPublicSale.selector));
    delicateDinos.mintDinoPublicSale{value: _fee}(address(this), "Firsty");

    delicateDinos.startDropClaim();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoPublicSale.selector));
    delicateDinos.mintDinoPublicSale{value: _fee}(address(this), "Firsty");

    delicateDinos.stopMint();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinos.NoPublicSale.selector));
    delicateDinos.mintDinoPublicSale{value: _fee}(address(this), "Firsty");
  }

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