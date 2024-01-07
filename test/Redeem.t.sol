// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {DataTypes} from "../contracts/libraries/types/DataTypes.sol";

contract RedeemTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testRedeem() public {
        _collateralize();
        vm.startPrank(richer1);
        uint256 loanId = collateralPoolLoan.getCollateralLoanId(BAYC, 7737);
        DataTypes.LoanData memory loanData = collateralPoolLoan.getLoan(loanId);
        sToken.approve(address(collateralPool), loanData.rewardAmount);
        uint256 repayAmount = collateralPool.redeem(BAYC, 7737);
        assertEq(IERC721(BAYC).ownerOf(7737), richer1);
        assertEq(repayAmount, loanData.rewardAmount);
        vm.stopPrank();
    }

    function testRedeemAfterBidAuction() public {
        _setAuction();
        _collateralize();
        vm.startPrank(richer1);
        sToken.approve(address(erc721), 10 * 1e18);
        erc721.bid(10 * 1e18);
        sToken.approve(address(collateralPool), 15475733742000000000);
        (bool success, ) = address(collateralPool).call{value: 10 ether}(abi.encodeWithSignature("redeem(address,uint256)", BAYC, 7737));
        require(success);
        assertEq(IERC721(BAYC).ownerOf(7737), richer1);
        vm.stopPrank();
    }

    function testRevertWithInvalidNFT() public {
        _collateralize();
        vm.startPrank(richer1);
        sToken.approve(address(collateralPool), 100 * 1e18);
        vm.expectRevert("NFT is not collateral");
        collateralPool.redeem(BAYC, 0);
    }

    function testRevertWithNotNftOwner() public{
        _collateralize();
        vm.startPrank(user1);
        sToken.approve(address(collateralPool), 100 * 1e18);
        vm.expectRevert("Not NFT owner");
        collateralPool.redeem(BAYC, 7737);
    }

    function testRevertWith3() public{
        _setAuction();
        _collateralize();
        vm.startPrank(richer1);
        sToken.approve(address(erc721), 10 * 1e18);
        erc721.bid(10 * 1e18);
        sToken.approve(address(collateralPool), 100 * 1e18);
        vm.expectRevert("Not enough balance for redeem");
        collateralPool.redeem(BAYC, 7737);
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
}