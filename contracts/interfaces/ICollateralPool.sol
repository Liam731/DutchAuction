// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICollateralPool {
    /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated Collateral pool
   */
  event Initialized(address indexed pool);
  
  function collateralize(address nftAsset, uint256 nftTokenId) external;
}
