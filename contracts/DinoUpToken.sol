// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

contract DinoUpToken is Ownable, ERC20 {
    mapping(address => uint256) claimable;    

    constructor() ERC20("Dino Up Token", "DNOUP") {}

    function getClaimableBalance(address addr) public view returns (uint256) {
        return claimable[addr];
    }

    function allocateToClaim(address addr, uint256 amt) public onlyOwner {
        claimable[addr] += amt;
    }

    function claim() public {
        require(claimable[msg.sender] > 0, "nothing to claim");
        _mint(msg.sender, claimable[msg.sender]);
    }
}
