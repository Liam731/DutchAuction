// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { CollateralizeSetUp } from "./helper/CollaterlizeSetup.sol";
import { console } from "forge-std/console.sol";
import { PunkWarriorErc721, ERC721, IERC721 } from "../contracts/PunkWarriorErc721.sol";
import { NFTOracle } from "../contracts/protocol/NFTOracle.sol";
import { CollateralPool } from "../contracts/protocol/CollateralPool.sol";
import { CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider } from "../contracts/protocol/CollateralPoolAddressesProvider.sol";
import { SToken } from "../contracts/protocol/SToken.sol";

contract SimpDutchAuction is CollateralizeSetUp {

    function setUp() public override {
        super.setUp();
    }
    
    function testDutchAuction() public {
        vm.startPrank(admin);
        // start DutchAuction
        PWDA.setAuction(
            block.timestamp, 
            block.timestamp+30 minutes, 
            1 minutes, 
            10*1e18, 
            0.1*1e18, 
            0.5*1e18, 
            20
            );
        // richer collateralize BAYC to get sToken
        vm.stopPrank();

        skip(3 minutes);
        vm.startPrank(richer);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        // richer place a bid for the auction item.
        sToken.approve(address(PWDA), 8.5*1e18);
        PWDA.bid(8.5*1e18);
        vm.stopPrank();

        skip(3 minutes);
        vm.startPrank(richer2);
        
        IERC721(BAYC).approve(address(collateralPool), 5904);
        collateralPool.collateralize(BAYC, 5904);
        // richer2 place a bid for the auction item.
        sToken.approve(address(PWDA), 7*1e18);
        PWDA.bid(7*1e18);

        vm.stopPrank();
        skip(30 minutes);
        PWDA.claimAuctionItem();
        PWDA.auctionData(1);
    }

}
