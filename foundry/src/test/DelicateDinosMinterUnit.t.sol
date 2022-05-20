// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DelicateDinosBaseIntegration.t.sol";

contract DelicateDinosMinterUnitTest is DelicateDinosBaseIntegrationTest {
  function setUp() external {
    init();
  }

  // ============ WHITELISTED MINT ============= //

  /// @notice cannot open whitelist mint round with zero maxmint
  function testCannotInitWhitelistWithZeroMaxMint() external {
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.SetupWithZeroMaxMint.selector));
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, 0, 0);
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

  function testCannotMintNonWhitelisted(address randomAddr) external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1);
    HEVM.expectRevert(abi.encodeWithSelector(WhitelistManager.InvalidProof.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(randomAddr, oneName, merkleProof, 1);
  }

  function testCannotMintWrongFeeWhitelisted(uint256 randomFee) external {
    delicateDinosMinter.startWhitelistMint(MERKLE_ROOT, DEFAULT_MINT_FEE, 1); // we allow for max 2, but only mint 1
    HEVM.assume(randomFee < DEFAULT_MINT_FEE);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.WrongMintFee.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: randomFee}(address(this), oneName, merkleProof, 1);
  }

   function testCanMintWhitelistedOnlyInWhitelistedMode() external {
    // initial state
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);

    delicateDinosMinter.startPublicSale(
      DEFAULT_INITIAL_SALE_PRICE,
      DEFAULT_MIN_SALE_PRICE,
      DEFAULT_SALE_DECREMENT,
      DEFAULT_SALE_INTERVAL,
      1 // max mintable
    );
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);

    delicateDinosMinter.stopMint();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NoWhitelistMint.selector));
    delicateDinosMinter.mintDinoWhitelisted{value: DEFAULT_MINT_FEE}(address(this), oneName, merkleProof, 1);
  }

  // ================ MINT PUBLIC SALE ================= // 

  /// @notice cannot open public sale with initial price < min price
  function testPublicSaleValidMinAndInitialPrice() external {
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.SetupWithInitialPriceBelowMinPrice.selector));
    delicateDinosMinter.startPublicSale(
      DEFAULT_MIN_SALE_PRICE - 1,
      DEFAULT_MIN_SALE_PRICE,
      DEFAULT_SALE_DECREMENT,
      DEFAULT_SALE_INTERVAL,
      1
    );
  }

  /// @notice cannot open public sale with zero maxmint
  function testCannotInitPublicSaleWithZeroMaxMint() external {
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.SetupWithZeroMaxMint.selector));
    delicateDinosMinter.startPublicSale(
      DEFAULT_INITIAL_SALE_PRICE,
      DEFAULT_MIN_SALE_PRICE,
      DEFAULT_SALE_DECREMENT,
      DEFAULT_SALE_INTERVAL,
      0
    );
  }

  /// @notice cannot mint in whitesale if numer of items and length of names array are not equal
  function testPublicSaleMintNamesNumberMismatch() external {
    delicateDinosMinter.startPublicSale(
      DEFAULT_INITIAL_SALE_PRICE,
      DEFAULT_MIN_SALE_PRICE,
      DEFAULT_SALE_DECREMENT,
      DEFAULT_SALE_INTERVAL,
      2
    );
    assertTrue(oneName.length == 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.NumberToMintAndNamesMismatch.selector));
    delicateDinosMinter.mintDinoPublicSale{value: DEFAULT_INITIAL_SALE_PRICE}(address(this), oneName, 2);
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

  

  function testPublicSaleClosesBelowMinPrice() external {

  }

  function testPriceDecreasesCorrectlyInPublicSale() external {
    uint256 initialSalePrice = 100e18;
    uint256 minSalePrice = 50e18;
    uint256 saleDecrement = 10e18;
    uint256 saleInterval = 3;
    uint256 startTime = block.timestamp;
    delicateDinosMinter.startPublicSale(
      initialSalePrice,
      minSalePrice,
      saleDecrement,
      saleInterval,
      1
    );
    uint256 epochs = (initialSalePrice - minSalePrice) / saleDecrement + 1;
    for (uint256 i = 0; i < epochs; i++) {
      HEVM.warp(startTime + i * saleInterval * 1 hours);
      assertTrue(delicateDinosMinter.currentSalePrice() == initialSalePrice - i * saleDecrement);
    }

    // warp to when sale is over
    HEVM.warp(startTime + epochs * saleInterval * 1 hours);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.PublicSaleIsOver.selector));
    delicateDinosMinter.mintDinoPublicSale{value: minSalePrice}(address(this), oneName, 1);
  }

  function testPublicSaleMintFailsWithWrongFee(uint256 random) external {
    uint256 initialSalePrice = 100e18;
    uint256 minSalePrice = 50e18;
    uint256 saleDecrement = 10e18;
    uint256 saleInterval = 3;
    uint256 startTime = block.timestamp;
    delicateDinosMinter.startPublicSale(
      initialSalePrice,
      minSalePrice,
      saleDecrement,
      saleInterval,
      1
    );
    uint256 epochs = (initialSalePrice - minSalePrice) / saleDecrement + 1;
    uint256 epoch = random % epochs;

    HEVM.warp(startTime + epoch * saleInterval * 1 hours);
    uint256 price = delicateDinosMinter.currentSalePrice();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.WrongMintFee.selector));
    delicateDinosMinter.mintDinoPublicSale{value: price+1}(address(this), oneName, 1);
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.WrongMintFee.selector));
    delicateDinosMinter.mintDinoPublicSale{value: price-1}(address(this), oneName, 1);
  }

  function testCannotMintPublicSaleAboveMaxMint() external {
    uint256 initialSalePrice = 100e18;
    uint256 minSalePrice = 50e18;
    uint256 saleDecrement = 10e18;
    uint256 saleInterval = 3;
    uint256 maxMint = 3;
    delicateDinosMinter.startPublicSale(
      initialSalePrice,
      minSalePrice,
      saleDecrement,
      saleInterval,
      maxMint
    );
    uint256 price = delicateDinosMinter.currentSalePrice();
    HEVM.expectRevert(abi.encodeWithSelector(DelicateDinosMinter.MintLimit.selector));
    delicateDinosMinter.mintDinoPublicSale{value: price * (maxMint + 1)}(address(this), fourNames, maxMint + 1);
  }

  function testCanMintPublicSaleUpToMaxMint() external {
    uint256 initialSalePrice = 100e18;
    uint256 minSalePrice = 50e18;
    uint256 saleDecrement = 10e18;
    uint256 saleInterval = 3;
    uint256 maxMint = 3;
    delicateDinosMinter.startPublicSale(
      initialSalePrice,
      minSalePrice,
      saleDecrement,
      saleInterval,
      maxMint
    );
    uint256 price = delicateDinosMinter.currentSalePrice();
    uint256 mintedBefore = delicateDinosMinter.mintedInSale(address(this));
    delicateDinosMinter.mintDinoPublicSale{value: price * 2}(address(this), twoNames, 2);
    uint256 mintedAfter1 = delicateDinosMinter.mintedInSale(address(this));
    assertTrue(mintedAfter1 == mintedBefore + 2);
    delicateDinosMinter.mintDinoPublicSale{value: price * 1}(address(this), oneName, 1);
    uint256 mintedAfter2 = delicateDinosMinter.mintedInSale(address(this));
    assertTrue(mintedAfter2 == mintedBefore + 3);
  }

  // TODO
  function testMintingStateMachine() external {
    // NOT SET => cant whitelisted mint, cant public sale mint

    // public sale or whitelisted => cant start public sale or whitelisted again

    // stopMinting() successfully resets both public sale and whitelisted
  }
}