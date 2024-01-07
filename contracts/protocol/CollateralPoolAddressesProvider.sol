// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";

contract CollateralPoolAddressesProvider is ICollateralPoolAddressesProvider {
    address admin;
    mapping(bytes32 => address) private _addresses;
    bytes32 private constant NFT_ORACLE = "NFT_ORACLE";
    bytes32 private constant COLLATERAL_POOL = "COLLATERAL_POOL";
    bytes32 private constant COLLATERAL_POOL_LOAN = "COLLATERAL_POOL_LOAN";
    bytes32 private constant COLLATERAL_POOL_HANDLER = "COLLATERAL_POOL_HANDLER";

    constructor() {
        admin = msg.sender;
    }

    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    function setAddress(bytes32 id, address newAddress) external override {
        require(admin == msg.sender, "Only admin can call this function");
        _addresses[id] = newAddress;
    }

    function getNftOracle() external view override returns (address) {
        return getAddress(NFT_ORACLE);
    }

    function getCollateralPool() external view override returns (address) {
        return getAddress(COLLATERAL_POOL);
    }

    function getCollateralPoolLoan() external view override returns (address) {
        return getAddress(COLLATERAL_POOL_LOAN);
    }

    function getCollateralPoolHandler() external view override returns (address) {
        return getAddress(COLLATERAL_POOL_HANDLER);
    }
}
