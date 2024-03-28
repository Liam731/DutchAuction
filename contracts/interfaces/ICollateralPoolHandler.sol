// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICollateralPoolHandler {
    function setCollateralFactor(uint256 newCollateralFactorMantissa) external returns (bool);

    function setLiquidateFactor(uint256 newLiquidateFactorMantissa) external returns (bool);

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (bool);

    function setBlueChipNFT(address nftAsset) external returns(bool);

    function isBlueChipNFT(address nftAsset) external view returns(bool);

    function getCollateralFactor() external view returns (uint256);

    function getLiquidateFactor() external view returns (uint256);

    function getLiquidationIncentive() external view returns (uint256);
}