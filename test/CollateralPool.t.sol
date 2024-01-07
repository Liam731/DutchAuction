// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {ICollateralPoolAddressesProvider} from "../contracts/interfaces/ICollateralPoolAddressesProvider.sol";

contract CollateralPoolTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testCollateralPoolAddressesProvider() public {
        address OracleOfBAYC = addressesProvider.getAddress(NFT_ORACLE);
        assertEq(OracleOfBAYC,chainlinkOracle);        
    }

    function testInitialized() public {
        vm.startPrank(admin);
        vm.expectRevert("Already initialized");
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.expectRevert("Already initialized");
        collateralPoolLoan.initialize(ICollateralPoolAddressesProvider(addressesProvider));
        vm.expectRevert("Already initialized");
        erc721.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.stopPrank();
    }

    function testWhitelist() public {
        vm.startPrank(admin);
        collateralPool.addToWhitelist(user1);
        bool isWhitelisted = collateralPool.isWhitelisted(user1);
        assertEq(isWhitelisted, true);
        collateralPool.removeFromWhitelist(user1);
        isWhitelisted = collateralPool.isWhitelisted(user1);
        assertEq(isWhitelisted, false);
        vm.stopPrank();
    }

    function testNotAdmin() public {
        vm.expectRevert("Only admin can call this function");
        addressesProvider.setAddress(COLLATERAL_POOL, address(collateralPool));
    }
}