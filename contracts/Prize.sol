// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Prize is Ownable {
    constructor() {}

    function transfer(address _winner) external onlyOwner {
        transferOwnership(_winner);
    }
}
