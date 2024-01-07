// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {DutchAuction} from "../contracts/DutchAuction.sol";
import {PunkWarriorErc721} from "../contracts/PunkWarriorErc721.sol";
import {ICollateralPoolAddressesProvider} from "../contracts/protocol/CollateralPoolAddressesProvider.sol";

contract DutchAuctionTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }

    function testDutchAuction() public {
        _richer1Bid();
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

    function testInitializeWithDutchAuction() public {
        vm.startPrank(admin);
        erc721 = new PunkWarriorErc721();
        erc721.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.stopPrank();
    }

    function testSetTokenURI() public {
        vm.startPrank(admin);
        erc721.setBaseURI("ipfs://QmfE1NWNVKtz7KaP2Ussz8xWcds6objCTekK6evn413eXh/1.json");
        vm.stopPrank();
    }

    function testGetAuctionPrice() public {
        _richer1Bid();
        uint256 price = erc721.getAuctionPrice();
        assertEq(price, 8.5 * 1e18);
    }

    function testGetPersonalBidData() public {
        _richer1Bid();
        DutchAuction.Bids memory bids = erc721.getPersonalBidData(1, 0);
        assertEq(bids.bidder, richer1);
        assertEq(bids.bidPrice, 8.5 * 1e18);
        assertEq(bids.itemIndex, 0);
        assertEq(bids.finalProcess, 1);
    }

    function testGetTokenId() public{
        testDutchAuction();
        string memory tokenURI = erc721.tokenURI(0);
        assertEq(tokenURI, "ipfs://QmfE1NWNVKtz7KaP2Ussz8xWcds6objCTekK6evn413eXh/1.json");
    }

    function testRevertWithdrawWithActionOngoing() public {
        _richer1Bid();
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        vm.expectRevert("Auction still in progress");
        erc721.withdraw(withdrawAmount, admin);
        vm.stopPrank();
    }
    
    function testRevertWithZeroAddress() public {
        _richer1Bid();
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        skip(30 minutes);
        erc721.claimAuctionItem();
        vm.expectRevert("Recipient is the zero address");
        erc721.withdraw(withdrawAmount, address(0));
        vm.stopPrank();
    }

    function testRevertWithTransferFailed() public {
        _richer1Bid();
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        skip(30 minutes);
        erc721.claimAuctionItem();
        vm.expectRevert("Transfer ETH failed");
        erc721.withdraw(withdrawAmount, address(collateralPool));
        vm.stopPrank();
    }

    function testRevertWithInsufficientBalance() public {
        _richer1Bid();
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        skip(30 minutes);
        erc721.claimAuctionItem();
        vm.expectRevert("Not enough balance for swap");
        erc721.withdraw(withdrawAmount + 1, admin);
        vm.stopPrank();
    }

    function testReverWithSwapFailed() public {
        _richer1Bid();
        vm.startPrank(admin);
        uint256 withdrawAmount = 8.5 * 1e18;

        skip(30 minutes);
        erc721.claimAuctionItem();
        vm.deal(address(collateralPool), 0);
        vm.expectRevert("Swap ETH failed");
        erc721.withdraw(withdrawAmount, admin);
        vm.stopPrank();
    }

    function testRevertWithTransferAuctionItem() public{
        vm.expectRevert("Only this contract can mint");
        erc721.tansferAuctionItem(user1, 1);
    }

    function testRevertWithAuctionNotRefund() public {
        _richer1Bid();
        skip(30 minutes);
        vm.startPrank(admin);
        erc721.setActionDeactivated();
        vm.expectRevert("Auction not refunded yet");
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

    function testRevertSetAuctionWithActionOngoing() public {
        _richer1Bid();
        vm.startPrank(admin);
        vm.expectRevert("Auction still in progress");
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

    function testRevertWithSetDeactivate() public {
        _richer1Bid();
        vm.expectRevert("Auction hasn't reached its end time yet");
        erc721.setActionDeactivated();
    }

    function _richer1Bid() internal {
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
        // richer1 collateralize BAYC to get sToken
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        // richer1 place a bid for the auction item.
        sToken.approve(address(erc721), 8.5 * 1e18);
        erc721.bid(8.5 * 1e18);
        vm.stopPrank();
    }
}
