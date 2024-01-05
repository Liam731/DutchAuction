// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ISToken} from "../interfaces/ISToken.sol";

contract SToken is ERC20, ISToken {
    address internal _collateralPool;

    constructor(address collateralPool) ERC20("Simp Token", "SToken") {
        _collateralPool = collateralPool;
    }
    
    modifier onlyCollateralPool() {
        require(msg.sender == _collateralPool, "Only collateral pool can mint");
        _;
    }

    function mint(address account, uint256 amount) external override onlyCollateralPool {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyCollateralPool {
        _burn(account, amount);
    }
}
