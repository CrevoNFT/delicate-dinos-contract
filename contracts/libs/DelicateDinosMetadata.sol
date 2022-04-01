
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library DelicateDinosMetadata {

  function dinoURI(uint256 tokenId, string memory imageUrl, uint8 teethLength, uint8 skinThickness, string memory name)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Delicate Dino #',
                                    Strings.toString(tokenId),
                                    '", "description": "Delicate Dinos is a randomly on-mint generated collection of delicate dinos who are afraid that bad things may be coming upon them.", "image": "',
                                    imageUrl,
                                    '","attributes":',
                                    _getTraitsAsString(teethLength, skinThickness, name),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }   

  function _getTraitsAsString(uint8 teethLength, uint8 skinThickness, string memory name) private view returns(string memory) {
        // Openning list bracket
        string memory traits = "[";

        // Name
        if (bytes(name).length != 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '{"trait_type":"Name",',
                    '"value":', 
                    name,
                    '},'
                )
            );
        }
        
        // Teeth
        traits = string(
            abi.encodePacked(
                traits,
                '{"trait_type":"Teeth length",',
                '"value":', 
                Strings.toString(teethLength), 
                '},'
            )
        );

        // Skin Thickness
        traits = string(
            abi.encodePacked(
                traits,
                '{"trait_type":"Skin thickness",',
                '"value":', 
                Strings.toString(skinThickness), 
                '}'
            )
        );

        // Closing bracket
        // NOTE: Make sure the entry above this closing bracket doesn't have a trailing comma
        traits = string(
            abi.encodePacked(
                traits,
                ']'
            )
        );
    }
}