// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./DelicateDinos.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";


contract DelicateDinosRandomness is VRFConsumerBase, Ownable {
  DelicateDinos delicateDinosContract;

  uint8 constant FAVOURED_MULTIPLIER = 3; // favoured candidates have 3 times higher chance of winning

  // =========== Randomness ============= //
  bytes32 internal keyHash; 
  uint256 internal vrfFee;

  event ReturnedRandomness(uint256 randomNumber);
  bytes32 lotteryRequestId;

  error NotEnoughLink();

  
  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(
      _vrfCoordinator, 
      _link
  ) {
    delicateDinosContract = DelicateDinos(msg.sender);
    keyHash = _keyHash;
    vrfFee = _fee;
  }

  function withdrawLink() public onlyOwner {
    LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
  }

  /// @notice Favoured tokenIds are whitelisted. Each of them has 
  /// a higher chance of winning in the lottery.
  /// @param tokenIds array of token ids which are favoured in the lottery
  function requestForDrop(uint16[] calldata tokenIds) external onlyOwner {
      uint256 mintIdx = delicateDinosContract.mintIndex();
      delicateDinosContract.applyFavouredTokenIds(tokenIds, FAVOURED_MULTIPLIER, mintIdx);
      lotteryRequestId = getRandomNumber();
  }

  /// @notice initiate request for a random number
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
          delicateDinosContract.performLotteryDrop(randomness);
      } else {
          delicateDinosContract.finalizeMintDino(requestId, randomness);
      }
  }

  function expandRandom(uint256 randomValue, uint256 n) external pure returns (uint256[] memory expandedValues) {
      expandedValues = new uint256[](n);
      for (uint256 i = 0; i < n; i++) {
          expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
      }
      return expandedValues;
  }


}