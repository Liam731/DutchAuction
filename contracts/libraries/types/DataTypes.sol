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

    struct ExecuteLiquidateParams {
        address initiator;
        address nftAsset;
        uint256 nftTokenId;
    }

    struct ExecuteSwapParams {
        address initiator;
        uint256 amountIn;
    }

    struct LoanData {
        address initiator;
        address nftAsset;
        uint256 nftTokenId;
        uint256 rewardAmount;
    }
}
