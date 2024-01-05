// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {PunkWarriorErc721} from "../contracts/PunkWarriorErc721.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {CollateralPool} from "../contracts/protocol/CollateralPool.sol";
import {CollateralPoolAddressesProvider, ICollateralPoolAddressesProvider} from "../contracts/protocol/CollateralPoolAddressesProvider.sol";
import {SToken} from "../contracts/protocol/SToken.sol";

contract DutchAuctionTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }

    function testDutchAuction() public {
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
        skip(3 minutes);
        // richer collateralize BAYC to get sToken
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        // richer place a bid for the auction item.
        sToken.approve(address(erc721), 8.5 * 1e18);
        erc721.bid(8.5 * 1e18);
        vm.stopPrank();

        skip(3 minutes);
        vm.startPrank(richer2);

        IERC721(BAYC).approve(address(collateralPool), 5904);
        collateralPool.collateralize(BAYC, 5904);
        // richer2 place a bid for the auction item.
        sToken.approve(address(erc721), 7 * 1e18);
        erc721.bid(7 * 1e18);

        vm.stopPrank();
        skip(30 minutes);
        erc721.claimAuctionItem();
        erc721.auctionData(1);
    }
    
    function testWithdraw() public {
        testDutchAuction();
        vm.startPrank(admin);
        sToken.balanceOf(address(erc721));
        uint256 beforeBalance = admin.balance;
        erc721.withdraw(14000000000000000000, admin);
        uint256 afterBalance = admin.balance;
        assertEq(afterBalance - beforeBalance, 14000000000000000000);
        vm.stopPrank();
    }
}
