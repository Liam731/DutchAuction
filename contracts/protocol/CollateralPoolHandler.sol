// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPoolHandler} from "../interfaces/ICollateralPoolHandler.sol";

contract CollateralPoolHandler is ICollateralPoolHandler {
    address admin;
    uint256 public collateralFactorMantissa;
    uint256 public liquidateFactorMantissa;
    uint256 public liquidationIncentiveMantissa;

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when a liquidate factor is changed by admin
    event NewLiquidationFactor(uint oldLiquidationFactorMantissa, uint newLiquidationFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function getCollateralFactor() external view returns (uint256) {
        return collateralFactorMantissa;
    }

    function getLiquidateFactor() external view returns (uint256) {
        return liquidateFactorMantissa;
    }

    function getLiquidationIncentive() external view returns (uint256) {
        return liquidationIncentiveMantissa;
    }

    function setCollateralFactor(uint256 newCollateralFactorMantissa) external override onlyAdmin returns (bool) {
        // Save current value for use in log
        uint256 oldCollateralFactorMantissa = collateralFactorMantissa;

        // Set liquidation incentive to new incentive
        collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return true;
    }

    function setLiquidateFactor(uint256 newLiquidateFactorMantissa) external override onlyAdmin returns (bool) {
        // Save current value for use in log
        uint256 oldLiquidateFactorMantissa = liquidateFactorMantissa;

        // Set liquidation incentive to new incentive
        liquidateFactorMantissa = newLiquidateFactorMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidateFactorMantissa, newLiquidateFactorMantissa);

        return true;
    }

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external override onlyAdmin returns (bool) {
        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return true;
    }
}
