// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";
import {SToken} from "./SToken.sol";

contract CollateralPoolStorage {
    address internal _admin;
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;
    bool internal _initialized;
    ICollateralPoolAddressesProvider internal _addressesProvider;
    SToken internal _sToken;
}
