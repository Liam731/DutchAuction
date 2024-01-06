// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {SToken} from "./protocol/SToken.sol";
import {IDutchAuctionManager} from "./interfaces/IDutchAuctionManager.sol";
import {ICollateralPool} from "./interfaces/ICollateralPool.sol";
import {ICollateralPoolAddressesProvider} from "./interfaces/ICollateralPoolAddressesProvider.sol";

contract DutchAuction {
    uint256 public auctionIndex; // Which auction round
    uint256 public bidIndex;
    uint256 public refundProgress;
    address public auctioner;
    mapping(uint256 => Auctions) public auctionData;
    mapping(uint256 => mapping(uint256 => Bids)) public allBids;
    bool internal _initialized;
    SToken internal _sToken;
    ICollateralPoolAddressesProvider internal _addressesProvider;

    event Bid(
        address indexed bidder,
        uint256 itemIndex,
        uint256 bidPrice,
        uint256 finalProcess
    );

    struct Auctions {
        uint256 startTime;
        uint256 endTime;
        uint256 timeStep;
        uint256 startPrice;
        uint256 endPrice;
        uint256 lastBidPrice;
        uint256 priceStep;
        uint256 totalForAuction;
        uint256 totalBids;
        bool isAuctionActivated;
        bool isAllRefunded;
    }

    struct Bids {
        address bidder;
        uint256 bidPrice;
        uint256 itemIndex;
        uint256 finalProcess; //0: No bid placed , 1: Bid placed, 2: Auction item claimed and sToken refunded
    }

    constructor() {
        auctioner = msg.sender;
    }

    modifier onlyAuctioner() {
        require(msg.sender == auctioner, "Only auctioner can call this function.");
        _;
    }

    function initialize(ICollateralPoolAddressesProvider provider,SToken sToken) external onlyAuctioner {
        require(!_initialized, "Already initialized");
        _addressesProvider = provider;
        _sToken = sToken;
        auctionData[auctionIndex].isAllRefunded = true;
        _initialized = true;
    }

    function setAuction(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _timeStep,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _totalForAuction
    ) external onlyAuctioner {
        require(msg.sender == auctioner, "Only auctionr is authorized to conduct auction");
        require(!auctionData[auctionIndex].isAuctionActivated,"Auction still in progress");
        require(auctionData[auctionIndex].isAllRefunded,"Auction not refunded yet");
        auctionIndex++;
        auctionData[auctionIndex].startTime = _startTime; // Start time
        auctionData[auctionIndex].endTime = _endTime; // End time
        auctionData[auctionIndex].timeStep = _timeStep; // Duration between deductions
        auctionData[auctionIndex].startPrice = _startPrice; // Initial price
        auctionData[auctionIndex].endPrice = _endPrice; // Final price
        auctionData[auctionIndex].priceStep = _priceStep; // Amount deducted each time
        auctionData[auctionIndex].totalForAuction = _totalForAuction; // Maximum quantity of auction items
        auctionData[auctionIndex].isAuctionActivated = true; // Is the auction currently being activated
    }

    function bid(uint256 bidPrice) external {
        Auctions memory currentAuction = auctionData[auctionIndex];
        Bids memory currentbids = allBids[auctionIndex][
            currentAuction.totalBids
        ];

        _bidAllowed(bidPrice, currentbids, currentAuction);

        _sToken.transferFrom(msg.sender, address(this), bidPrice);
        currentbids.bidder = msg.sender;
        currentbids.itemIndex = currentAuction.totalBids;
        currentbids.bidPrice = bidPrice;
        currentbids.finalProcess = 1;
        currentAuction.lastBidPrice = bidPrice;
        currentAuction.totalBids++;

        emit Bid(
            currentbids.bidder,
            currentbids.itemIndex,
            currentbids.bidPrice,
            currentbids.finalProcess
        );
        auctionData[auctionIndex] = currentAuction;
        allBids[auctionIndex][currentbids.itemIndex] = currentbids;
    }

    function claimAuctionItem() external {
        Auctions memory currentAuction = auctionData[auctionIndex];
        if (block.timestamp > currentAuction.endTime) {
            currentAuction.isAuctionActivated = false;
        } else {
            revert("Auction still in progress");
        }
        uint256 _refundProgress = refundProgress;
        uint256 _totalBids = currentAuction.totalBids;
        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 lastPrice = currentAuction.lastBidPrice;

        for (uint256 i = _refundProgress; gasUsed < 5000000 && i < _totalBids; i++
        ) {
            Bids memory currentbids = allBids[auctionIndex][i];
            require(
                IDutchAuctionManager(address(this)).tansferAuctionItem(
                    currentbids.bidder,
                    currentbids.itemIndex
                ),
                "Invalid auction executor return"
            );
            uint256 refund = currentbids.bidPrice - lastPrice;
            if (refund > 0) {
                _sToken.transfer(currentbids.bidder, refund);
            }
            currentbids.finalProcess = 2;
            allBids[auctionIndex][i] = currentbids;
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            _refundProgress++;
        }

        refundProgress = _refundProgress;
        if (refundProgress >= _totalBids) {
            currentAuction.isAllRefunded = true;
            auctionData[auctionIndex] = currentAuction;
        }
    }

    function withdraw(uint256 amount, address to) external onlyAuctioner {
        require(!auctionData[auctionIndex].isAuctionActivated,"Auction still in progress");
        address collateralPool = _addressesProvider.getCollateralPool();
        ICollateralPool(collateralPool).swapExactTokensForETH(amount);
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer ETH failed");
    }

    function getPersonalBidData(
        uint256 _auctionIndex,
        uint256 _itemIndex
    ) external view returns (Bids memory) {
        return allBids[_auctionIndex][_itemIndex];
    }

    receive() external payable {}

    function getAuctionPrice() public view returns (uint256) {
        Auctions memory currentAuction = auctionData[auctionIndex];

        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }
        uint256 step = (block.timestamp - currentAuction.startTime) /
            currentAuction.timeStep;
        return
            currentAuction.startPrice > step * currentAuction.priceStep
                ? currentAuction.startPrice - step * currentAuction.priceStep
                : currentAuction.endPrice;
    }

    function _bidAllowed(
        uint256 bidPrice,
        Bids memory currentbids,
        Auctions memory currentAuction
    ) internal view {
        if (block.timestamp > currentAuction.endTime) {
            currentAuction.isAuctionActivated = false;
        }
        require(currentAuction.isAuctionActivated, "Auction not activated");
        require(block.timestamp >= currentAuction.startTime,"Auction not started");
        require(currentAuction.totalBids < currentAuction.totalForAuction,"Auction is full");
        require(_sToken.balanceOf(msg.sender) >= bidPrice,"Insuficient token balance");
        require(bidPrice >= getAuctionPrice(), "Bid price not high enough");
        require(currentbids.finalProcess == 0, "Bid not placed");
    }
}
