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
    }
    
    function testWithdraw() public {
        testDutchAuction();
        vm.startPrank(admin);
        uint256 beforeBalance = admin.balance;
        uint256 withdrawAmount = 14 * 1e18;
        erc721.withdraw(withdrawAmount, admin);
        uint256 afterBalance = admin.balance;
        assertEq(afterBalance - beforeBalance, withdrawAmount);
        vm.stopPrank();
    }

    function testWithdrawRevert() public {
        vm.startPrank(admin);
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
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(erc721), 8.5 * 1e18);
        erc721.bid(8.5 * 1e18);
        vm.stopPrank();
        
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        vm.expectRevert("Auction still in progress");
        erc721.withdraw(withdrawAmount, admin);

        skip(30 minutes);
        erc721.claimAuctionItem();
        vm.expectRevert("Recipient is the zero address");
        erc721.withdraw(withdrawAmount, address(0));

        // Collateral pool without receive function
        vm.expectRevert("Transfer ETH failed");
        erc721.withdraw(withdrawAmount, address(collateralPool));
        
        vm.expectRevert("Not enough balance for swap");
        erc721.withdraw(withdrawAmount + 1, admin);

        vm.deal(address(collateralPool), 0);
        vm.expectRevert("Swap ETH failed");
        erc721.withdraw(withdrawAmount, admin);

        collateralPool.removeFromWhitelist(address(erc721));
        vm.expectRevert("Not in whitelist");
        erc721.withdraw(withdrawAmount, admin);
        vm.stopPrank();
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

    function testBidAllowed() public {
        vm.startPrank(admin);
        erc721.setAuction(
            block.timestamp + 10 minutes,
            block.timestamp + 30 minutes,
            1 minutes,
            10 * 1e18,
            0.1 * 1e18,
            0.5 * 1e18,
            1
        );
        vm.stopPrank();
        
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(erc721), 8.5 * 1e18);
        vm.expectRevert("Auction not started");
        erc721.bid(8.5 * 1e18);

        skip(13 minutes);
        vm.expectRevert("Bid price not high enough");
        erc721.bid(8 * 1e18);

        vm.expectRevert("Insuficient token balance");
        erc721.bid(30 * 1e18);

        erc721.bid(8.5 * 1e18);
        vm.stopPrank();
        skip(3 minutes);
        vm.startPrank(richer2);
        IERC721(BAYC).approve(address(collateralPool), 5904);
        collateralPool.collateralize(BAYC, 5904);
        sToken.approve(address(erc721), 7 * 1e18);
        vm.expectRevert("Auction is full");
        erc721.bid(7 * 1e18);
        
        skip(30 minutes);
        vm.expectRevert("Auction not activated");
        erc721.bid(7 * 1e18);
        vm.stopPrank();
    }
}
