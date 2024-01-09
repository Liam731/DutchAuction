// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {DataTypes} from "../contracts/libraries/types/DataTypes.sol";

contract LiquidateTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testLiquidate() public {
        uint256 richer1BeforeBalance = richer1.balance;
        _collateralize();
        _setCollateralAsLiquidatable();
        uint256 liquidateRequireAmount = _liquidate();
        uint256 richer1AfterBalance = richer1.balance;
        assertEq(IERC721(BAYC).ownerOf(7737), user1);
        assertEq(richer1AfterBalance - richer1BeforeBalance, liquidateRequireAmount);
        assertEq(sToken.balanceOf(richer1), 0);
    }

    function testLiquidateAfterBidAuction() public {
        uint256 richer1BeforeBalance = richer1.balance;
        _setAuction();
        _collateralize();
        vm.startPrank(richer1);
        uint256 bidPrice = 10 * 1e18;
        sToken.approve(address(erc721), bidPrice);
        erc721.bid(bidPrice);
        vm.stopPrank();
        _setCollateralAsLiquidatable();
        uint256 liquidateRequireAmount = _liquidate();
        uint256 richer1AfterBalance = richer1.balance;
        assertEq(IERC721(BAYC).ownerOf(7737), user1);
        assertEq(richer1AfterBalance - richer1BeforeBalance, liquidateRequireAmount - bidPrice);
        assertEq(sToken.balanceOf(richer1), 0);
    }

    function testRevertWithInvalidNFT() public {
        _collateralize();
        _setCollateralAsLiquidatable();
        vm.expectRevert("NFT is not collateral");
        (bool success, ) = address(collateralPool).call{value:10 ether}(abi.encodeWithSignature("liquidate(address,uint256)", BAYC, 0));
        require(success);
    }

    function testRevertWithHealthFactor() public {
        _collateralize();
        vm.expectRevert("Liquidation cannot be executed, health factor must be less than 1");
        (bool success, ) = address(collateralPool).call{value:10 ether}(abi.encodeWithSignature("liquidate(address,uint256)", BAYC, 7737));
        require(success);
    }

    function testRevertWithLowBalance() public {
        _collateralize();
        _setCollateralAsLiquidatable();
        vm.expectRevert("Not enough balance for liquidation");
        (bool success, ) = address(collateralPool).call{value:10 ether}(abi.encodeWithSignature("liquidate(address,uint256)", BAYC, 7737));
        require(success);
    }

    function _setAuction() internal {
        vm.startPrank(admin);
        // start DutchAuction
        erc721.setAuction(
            block.timestamp,
            block.timestamp + 30 minutes,
            1 minutes,
            10 * 1e18,
            0.1 * 1e18,
            0.5 * 1e18,
            20
        );
        vm.stopPrank();
    }

    function _collateralize() internal {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        vm.stopPrank();
    }

    function _setCollateralAsLiquidatable() internal {
        vm.startPrank(admin);
        handler.setCollateralFactor(20 * 1e16);
        vm.stopPrank();
    }

    function _liquidate() internal returns(uint256) {
        vm.startPrank(user1);
        uint256 incentive = handler.getLiquidationIncentive();
        uint256 currentPrice = uint256(nftOracle.getLatestPrice());
        uint256 liquidateRequireAmount = currentPrice - (currentPrice * incentive / 1e18);
        (bool success, ) = address(collateralPool).call{value : liquidateRequireAmount}(abi.encodeWithSignature("liquidate(address,uint256)", BAYC, 7737));
        require(success);
        vm.stopPrank();
        return liquidateRequireAmount;
    }
}
