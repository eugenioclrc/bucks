// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockBtc is ERC20 {
    constructor() ERC20("MockBtc", "wBTC", 8) {
        _mint(msg.sender, 100 ether);
    }
}