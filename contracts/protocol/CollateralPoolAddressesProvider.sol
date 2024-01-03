// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";

contract CollateralPoolAddressesProvider is ICollateralPoolAddressesProvider {
    address admin;
    mapping(bytes32 => address) private _addresses;
    bytes32 private constant NFT_ORACLE = "NFT_ORACLE";

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function getAddress(bytes32 id) public view returns (address) {
        return _addresses[id];
    }

    function setAddress(bytes32 id, address newAddress) external onlyAdmin {
        _addresses[id] = newAddress;
    }

    function getNFTOracle() external view returns (address) {
        return getAddress(NFT_ORACLE);
    }
}
