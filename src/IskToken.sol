// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ISK is ERC20 {
    constructor() ERC20("Isekai Token", "ISK") {
        _mint(msg.sender, 27000000000 * (10 ** uint256(decimals())));
    }
}
