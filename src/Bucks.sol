// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ERC20} from "solady/tokens/ERC20.sol";

contract BucksToken is ERC20 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "OnlyOwner");
        owner = newOwner;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "OnlyOwner");
        _mint(to, amount);
    }

    function burn(address user, uint256 amount) external {
        _spendAllowance(user, msg.sender, amount);
        _burn(user, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function name() public pure override returns (string memory) {
        return "Bucks";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public pure override returns (string memory) {
        return "BUX";
    }
}
