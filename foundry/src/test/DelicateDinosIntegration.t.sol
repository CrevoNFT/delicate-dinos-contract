// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DelicateDinosBaseIntegration.t.sol";

contract DelicateDinosIntegrationTest is DelicateDinosBaseIntegrationTest {
  function setUp() external {
    init();
  }

  // ============ WHITELISTED MINT ============= //

  function testCanMintWhitelisted() external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1);
    assertTrue(delicateDinos.supply() == 0);
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);
    assertTrue(delicateDinos.supply() == 1);
    bytes32 requestId = delicateDinos.getTokenIdToMintRequestId(1);
    _vrfRespondMint(RANDOM_NUMBER, requestId);
    assertTrue(delicateDinos.ownerOf(1) == address(this));
    // emit log_string(delicateDinos.tokenURI(1));
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

  // ================ MINT PUBLIC SALE ================= // 


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