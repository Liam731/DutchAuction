// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DataTypes {
    struct ExecuteCollateralizeParams {
        address collateralProvider;
        address nftAsset;
        uint256 nftTokenId;
    }
}
