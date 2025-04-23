// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FitechToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("FitechToken", "FIT") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10**18); // Optional initial supply
    }

    // Mint function for testing
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}