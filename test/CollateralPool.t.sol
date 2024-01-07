// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {ICollateralPoolAddressesProvider} from "../contracts/interfaces/ICollateralPoolAddressesProvider.sol";

contract CollateralPoolTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testCollateralPoolAddressesProvider() public {
        address OracleOfBAYC = addressesProvider.getAddress(NFT_ORACLE);
        assertEq(OracleOfBAYC,chainlinkOracle);        
    }

    function testNFTOracle() public {
        vm.startPrank(admin);      
        NFTOracle oracle = new NFTOracle();  
        //Set Azuki NFT address
        oracle.setNftAddress(0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74);
        int AzukiPrice = oracle.getLatestPrice();
        console.logInt(AzukiPrice);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert("Only admin can change NFT address");
        oracle.setNftAddress(0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74);
        vm.stopPrank();
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