// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";

contract RedeemTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }
    
    function testRedeem() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        assertEq(IERC721(BAYC).ownerOf(7737), address(collateralPool));

        sToken.approve(address(collateralPool), 15475733742000000000);
        uint256 repayAmount = collateralPool.redeem(BAYC, 7737);
        assertEq(IERC721(BAYC).ownerOf(7737), richer1);
        assertEq(repayAmount, 15475733742000000000);
        vm.stopPrank();
    }

    function testRedeemAfterBidAuction() public {
        _setAuction();
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(erc721), 10 * 1e18);
        erc721.bid(10 * 1e18);
        sToken.balanceOf(richer1);
        sToken.approve(address(collateralPool), 15475733742000000000);
        (bool success, ) = address(collateralPool).call{value: 10 ether}(abi.encodeWithSignature("redeem(address,uint256)", BAYC, 7737));
        require(success);
        assertEq(IERC721(BAYC).ownerOf(7737), richer1);
        vm.stopPrank();
    }

    function _setAuction() public {
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
}
