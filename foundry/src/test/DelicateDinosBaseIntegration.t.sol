// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../lib/ds-test/src/test.sol";
import "../Hevm.sol";
import "../contracts/mocks/MockDelicateDinos.sol";
import "../contracts/mocks/MockDelicateDinosMinter.sol";
import "../contracts/mocks/MockDinoUpToken.sol";
import "../contracts/mocks/MockDelicateDinosRandomness.sol";
import "../contracts/mocks/MockDelicateDinosRaffle.sol";
import "../contracts/mocks/chainlink/LinkToken.sol";
import "../contracts/mocks/chainlink/MockVRFOracle.sol";

contract DelicateDinosBaseIntegrationTest is DSTest {

    // HEVM for cheat codes
    Hevm internal constant HEVM = Hevm(HEVM_ADDRESS);

    MockDelicateDinos public delicateDinos;
    MockDelicateDinosMinter public delicateDinosMinter;
    MockDinoUpToken public dinoUpToken;
    MockDelicateDinosRaffle public raffleContract;
    MockDelicateDinosRandomness public randomnessProvider;

    // Mock VRF stuff
    LinkToken public linkToken;
    VRFCoordinatorMock public vrfCoordinator;
    MockVRFOracle public mockVRFOracle;

    uint256 constant RANDOM_NUMBER = 12312412121357;  
    bytes32[] merkleProof;
    bytes32 constant MERKLE_ROOT = bytes32(0xe99abc00c34b105cee0fb029ef32528d15ac5ed72d3fe510d675f3cc599de199);
    uint256 constant DEFAULT_MINT_FEE = 1e18;
    uint256 constant DEFAULT_INITIAL_SALE_PRICE = 10e18;
    uint256 constant DEFAULT_MIN_SALE_PRICE = 1e18;
    uint256 constant DEFAULT_SALE_DECREMENT = 1e17; 
    uint256 constant DEFAULT_SALE_INTERVAL = 1; // hours

    string[] public oneName;
    string[] public oneName2;
    string[] public twoNames;
    string[] public threeNames;
    string[] public fourNames;

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

        delicateDinosMinter = new MockDelicateDinosMinter(address(delicateDinos));
        delicateDinos.setMinterContract(address(delicateDinosMinter));

        mockVRFOracle = new MockVRFOracle(
            address(delicateDinos.randomnessProvider()),
            address(vrfCoordinator)
        );
        linkToken.transfer(address(delicateDinos.randomnessProvider()), 1000000000000000000);

        oneName.push("Firsty");
        oneName2.push("Secondy");
        twoNames.push("Firsty");
        twoNames.push("Secondy");
        threeNames.push("Firsty");
        threeNames.push("Secondy");
        threeNames.push("Thirdy");
        fourNames.push("Firsty");
        fourNames.push("Secondy");
        fourNames.push("Thirdy");
        fourNames.push("Fourty");

        merkleProof.push(bytes32(0x702d0f86c1baf15ac2b8aae489113b59d27419b751fbf7da0ef0bae4688abc7a));
        merkleProof.push(bytes32(0xb159efe4c3ee94e91cc5740b9dbb26fc5ef48a14b53ad84d591d0eb3d65891ab));
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