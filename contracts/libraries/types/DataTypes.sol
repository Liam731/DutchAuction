// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DataTypes {
    struct ExecuteCollateralizeParams {
        address initiator;
        address nftAsset;
        uint256 nftTokenId;
    }

    struct ExecuteRedeemParams {
        address initiator;
        address nftAsset;
        uint256 nftTokenId;
    }

    struct LoanData {
        address initiator;
        address nftAsset;
        uint256 nftTokenId;
    }
}
