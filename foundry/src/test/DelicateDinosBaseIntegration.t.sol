// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "../contracts/mocks/MockDelicateDinos.sol";
import "../contracts/mocks/MockDinoUpToken.sol";
import "../contracts/mocks/MockDelicateDinosUpgrader.sol";
import "../contracts/mocks/chainlink/LinkToken.sol";
import "../contracts/mocks/chainlink/MockVRFOracle.sol";

contract DelicateDinosBaseIntegrationTest is DSTest {

    // HEVM for cheat codes
    Hevm internal constant HEVM = Hevm(HEVM_ADDRESS);

    MockDelicateDinos public delicateDinos;
    MockDinoUpToken public dinoUpToken;

    // Mock VRF stuff
    LinkToken public linkToken;
    VRFCoordinatorMock public vrfCoordinator;
    MockVRFOracle public mockVRFOracle;

    // Mock upgrade contract
    MockDelicateDinosUpgrader public upgrader;

    function init() internal {

        // Chainlnk
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        mockVRFOracle = new MockVRFOracle(
            address(delicateDinos),
            address(vrfCoordinator)
        );

        // Dinos
        delicateDinos = new MockDelicateDinos(
            address(vrfCoordinator),
            address(linkToken),
            0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,
            0.0001 * 10 ** 18
        );

        dinoUpToken = new MockDinoUpToken();  

        upgrader = new MockDelicateDinosUpgrader();

        linkToken.transfer(address(delicateDinos), 1000000000000000000);
        
        delicateDinos.setUpgraderContract(address(upgrader));

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
            address(delicateDinos)
        );
    }
}