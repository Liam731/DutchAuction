// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {CollateralPool} from "../contracts/protocol/CollateralPool.sol";
import {CollateralPoolLoan} from "../contracts/protocol/CollateralPoolLoan.sol";
import {ICollateralPoolAddressesProvider} from "../contracts/interfaces/ICollateralPoolAddressesProvider.sol";

contract CollateralPoolTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testCollateralPoolAddressesProvider() public {
        address OracleOfBAYC = addressesProvider.getAddress(NFT_ORACLE);
        assertEq(OracleOfBAYC,chainlinkOracle);        
    }

    function testHandlerSetCollateralFactor() public {
        vm.startPrank(admin);
        handler.setCollateralFactor(1 * 1e18);
        assertEq(handler.getCollateralFactor(), 1 * 1e18);
        vm.stopPrank();
    }

    function testHandlerSetLiquidateFactor() public {
        vm.startPrank(admin);
        handler.setLiquidateFactor(1 * 1e18);
        assertEq(handler.getLiquidateFactor(), 1 * 1e18);
        vm.stopPrank();
    }

    function testHandlerSetLiquidationIncentive() public {
        vm.startPrank(admin);
        handler.setLiquidationIncentive(1 * 1e18);
        assertEq(handler.getLiquidationIncentive(), 1 * 1e18);
        vm.stopPrank();
    }

    function testInitializeWithCollateralPool() public {
        vm.startPrank(admin);
        collateralPool = new CollateralPool();
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.stopPrank();
    }

    function testInitializeWithCollateralPoolLoan() public {
        vm.startPrank(admin);
        collateralPoolLoan = new CollateralPoolLoan();
        collateralPoolLoan.initialize(ICollateralPoolAddressesProvider(addressesProvider));
        vm.stopPrank();
    }

    function testNFTOracle() public {
        vm.startPrank(admin);      
        NFTOracle oracle = new NFTOracle();  
        //Set Azuki NFT address
        oracle.setNftAddress(PriceFeedOfAZUKI);
        int azukiPrice = oracle.getLatestPrice();
        assertGt(azukiPrice, 0);
        vm.stopPrank();
    }

    function testSetAddress() public {
        vm.startPrank(admin);
        addressesProvider.setAddress(COLLATERAL_POOL, address(collateralPool));
        vm.stopPrank();
    }

    function testAddWhitelist() public {
        vm.startPrank(admin);
        collateralPool.addToWhitelist(user1);
        bool isWhitelisted = collateralPool.isWhitelisted(user1);
        assertEq(isWhitelisted, true);
        vm.stopPrank();
    }

    function testRemoveWhitelist() public {
        vm.startPrank(admin);
        collateralPool.addToWhitelist(user1);
        collateralPool.removeFromWhitelist(user1);
        bool isWhitelisted = collateralPool.isWhitelisted(user1);
        assertEq(isWhitelisted, false);
        vm.stopPrank();
    }

    function testRevertWithNotOracleAdmin() public {
        vm.startPrank(admin);
        NFTOracle oracle = new NFTOracle();
        vm.stopPrank(); 
        vm.startPrank(user1);
        vm.expectRevert("Only admin can change NFT address");
        oracle.setNftAddress(PriceFeedOfAZUKI);
        vm.stopPrank();
    }

    function testRevertWithNotWhitelist() public {
        vm.startPrank(admin);
        vm.expectRevert("Not in whitelist");
        collateralPool.swapExactTokensForETH(10 ether);
        vm.stopPrank();
    }

    function testRevertWithPoolInitialize() public {
        vm.startPrank(admin);
        vm.expectRevert("Already initialized");
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.stopPrank();
    }

    function testRevertWithPoolLoanInitialize() public {
        vm.startPrank(admin);
        vm.expectRevert("Already initialized");
        collateralPoolLoan.initialize(ICollateralPoolAddressesProvider(addressesProvider));
        vm.stopPrank();
    }

    function testRevertWithActionInitialize() public {
        vm.startPrank(admin);
        vm.expectRevert("Already initialized");
        erc721.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.stopPrank();
    }

    function testNotAdmin() public {
        vm.expectRevert("Only admin can call this function");
        addressesProvider.setAddress(COLLATERAL_POOL, address(collateralPool));
    }
}