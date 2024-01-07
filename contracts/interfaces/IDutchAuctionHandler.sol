// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
 * @title IDutchAuctionManager
 * @author SimpDutchAuction
 * @notice Defines the basic interface of a dutch-auction-receiver contract.
 * @dev Implement this interface to develop a dutch-auction-compatible dutchAuctionReceiver contract
 */
interface IDutchAuctionHandler {
  /**
   * @notice Executes an operation after transfer sToken to the auction
   * @dev Ensure that the bidder can claim the their auction item
   * @param bidder The address of the auction bidder
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function tansferAuctionItem(
    address bidder,
    uint256 itemIndex
  ) external returns (bool);

}