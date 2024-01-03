// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SToken is ERC20 {
    address internal pool;

    constructor(address _pool) ERC20("Simp Token", "SToken") {
        pool = _pool;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == pool, "Only collateral pool can mint");
        _mint(account, amount);
    }
}
