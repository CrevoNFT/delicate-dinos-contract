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
  bytes32 impactRequestId;

  error NotEnoughLink();
  error NotTheWithdrawer();

  // ============= Withdrawals ============== // 

  address public withdrawer;
  modifier onlyWithdrawer() {
    if (msg.sender != withdrawer) revert NotTheWithdrawer();
    _;
  }
  
  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(
      _vrfCoordinator, 
      _link
  ) {
    keyHash = _keyHash;
    vrfFee = _fee;
  }

  function initMaster(address _dinosContract) public onlyOwner {
    delicateDinosContract = DelicateDinos(_dinosContract);
    withdrawer = delicateDinosContract.owner();
  }

  function withdrawLink() public onlyOwner {
    LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
  }

  function changeWithdrawer(address _withdrawer) public onlyWithdrawer {
    withdrawer = _withdrawer;
  }

  /// @notice request for a randomness seed to use in the drop lottery
  function requestForDrop() external onlyOwner {
      lotteryRequestId = getRandomNumber();
  }

  /// @notice initiate request for a random number
  function getRandomNumber() public returns (bytes32 requestId) {
      if (LINK.balanceOf(address(this)) < vrfFee) revert NotEnoughLink();
      return requestRandomness(keyHash, vrfFee);
  }

  /// @notice request for a randomness seed to use in the impact simpulation
  function requestForImpact() external onlyOwner {
      impactRequestId = getRandomNumber();
  }

  /**
  * Callback function used by VRF Coordinator
  */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      emit ReturnedRandomness(randomness);
      if (requestId == lotteryRequestId) {
          delicateDinosContract.performLotteryDrop(randomness);
      } else if (requestId == impactRequestId) {
          delicateDinosContract.performImpact(randomness);
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