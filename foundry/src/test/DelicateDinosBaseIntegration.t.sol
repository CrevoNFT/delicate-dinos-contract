// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "../contracts/mocks/MockDelicateDinos.sol";
import "../contracts/mocks/MockDinoUpToken.sol";
import "../contracts/mocks/MockDelicateDinosRandomness.sol";
import "../contracts/mocks/MockDelicateDinosRaffle.sol";
import "../contracts/mocks/chainlink/LinkToken.sol";
import "../contracts/mocks/chainlink/MockVRFOracle.sol";

contract DelicateDinosBaseIntegrationTest is DSTest {

    // HEVM for cheat codes
    Hevm internal constant HEVM = Hevm(HEVM_ADDRESS);

    MockDelicateDinos public delicateDinos;
    MockDinoUpToken public dinoUpToken;
    MockDelicateDinosRaffle public raffleContract;
    MockDelicateDinosRandomness public randomnessProvider;

    // Mock VRF stuff
    LinkToken public linkToken;
    VRFCoordinatorMock public vrfCoordinator;
    MockVRFOracle public mockVRFOracle;

    function init() internal {

        // Dino up token
        dinoUpToken = new MockDinoUpToken();  

        // Dinos with chainlink
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        randomnessProvider = new MockDelicateDinosRandomness(
            address(vrfCoordinator),   
            address(linkToken),
            0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,
            0.0001 * 10 ** 18
        );
        raffleContract = new MockDelicateDinosRaffle(
            address(randomnessProvider)
        );
        delicateDinos = new MockDelicateDinos(
            address(randomnessProvider),
            address(raffleContract),
            address(dinoUpToken)
        );
        randomnessProvider.initMaster(address(delicateDinos));
        mockVRFOracle = new MockVRFOracle(
            address(delicateDinos.randomnessProvider()),
            address(vrfCoordinator)
        );
        linkToken.transfer(address(delicateDinos.randomnessProvider()), 1000000000000000000);
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