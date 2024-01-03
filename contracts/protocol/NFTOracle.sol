// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {INFTOracle} from "../interfaces/INFTOracle.sol";

contract NFTOracle {
    address internal priceFeedAdmin;
    INFTOracle internal nftFloorPriceFeed;

    /**
     * Network: Goerli - No Sepolia feeds available at this time
     * Aggregator: BoredApeYachtClub
     * Address: 0xB677bfBc9B09a3469695f40477d05bc9BcB15F50
     */
    constructor() {
        nftFloorPriceFeed = INFTOracle(
            0xB677bfBc9B09a3469695f40477d05bc9BcB15F50
        );
        priceFeedAdmin = msg.sender;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int nftFloorPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nftFloorPriceFeed.latestRoundData();
        return nftFloorPrice;
    }

    function setNftAddress(address nftAddress) public returns (bool) {
        require(msg.sender == priceFeedAdmin, "NFTOracle: only admin can change NFT address");
        nftFloorPriceFeed = INFTOracle(nftAddress);
        return true;
    }
}
