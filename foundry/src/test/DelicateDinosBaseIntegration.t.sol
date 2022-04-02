// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "../contracts/mocks/MockDelicateDinos.sol";
import "../contracts/interfaces/IDinoUpToken.sol";
import "../contracts/mocks/chainlink/LinkToken.sol";
import "../contracts/mocks/chainlink/MockVRFOracle.sol";

contract DelicateDinosBaseIntegrationTest is DSTest {

    // HEVM for cheat codes
    Hevm internal constant HEVM = Hevm(HEVM_ADDRESS);

    MockDelicateDinos public delicateDinos;
    IDinoUpToken public dinoUpToken;

    // Mock VRF stuff
    LinkToken public linkToken;
    VRFCoordinatorMock public vrfCoordinator;
    MockVRFOracle public mockVRFOracle;

    function init() internal {
        // Dinos with chainlink

        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        delicateDinos = new MockDelicateDinos(
            address(vrfCoordinator),   
            address(linkToken),
            0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,
            0.0001 * 10 ** 18
        );
        mockVRFOracle = new MockVRFOracle(
            address(delicateDinos.randomnessProvider()),
            address(vrfCoordinator)
        );
        linkToken.transfer(address(delicateDinos.randomnessProvider()), 1000000000000000000);

        // up token
        dinoUpToken = IDinoUpToken(address(delicateDinos.dinoUpToken()));  
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) pure external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ============== VRF Helpers =============== // 

    function _vrfRespondMint(uint256 randomNumber, bytes32 requestId) internal {
        mockVRFOracle.callBackWithRandomness(
            requestId,
            randomNumber,
            address(delicateDinos.randomnessProvider())
        );
    }
}