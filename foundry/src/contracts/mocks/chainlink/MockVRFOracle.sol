// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorMock.sol";
// import "../../../tests/solidity/Hevm.sol";

contract MockVRFOracle {
    VRFConsumerBase internal vrfConsumer;
    VRFCoordinatorMock internal vrfCordinator;

    constructor(address _vrfConsumer, address _vrfCoordinator) {
        vrfConsumer = VRFConsumerBase(_vrfConsumer);
        vrfCordinator = VRFCoordinatorMock(_vrfCoordinator);
    }

    function callBackWithRandomness(
        bytes32 requestId,
        uint256 randomness,
        address returnAddress
    ) public {
        vrfCordinator.callBackWithRandomness(
            requestId,
            randomness,
            returnAddress
        );
    }
}
