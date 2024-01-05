// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICollateralPool {
  event Initialized(address indexed provider, address indexed sToken);

  function collateralize(address nftAsset, uint256 nftTokenId) external;

  function redeem(address nftAsset, uint256 nftTokenId) external payable returns (uint256);

  function swapExactTokensForETH(uint256 amountIn) external;
}
