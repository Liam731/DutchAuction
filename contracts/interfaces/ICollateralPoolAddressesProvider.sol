// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICollateralPoolAddressesProvider {
  function setAddress(bytes32 id, address newAddress) external;

  function getAddress(bytes32 id) external view returns (address);

  function getNftOracle() external view returns (address);

  function getCollateralPool() external view returns (address);

  function getCollateralPoolLoan() external view returns (address);
}