// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ICollateralPoolLoan {
    event Initialized(address indexed provider);

    event LoanCreated(address indexed user, uint256 indexed loanId, address nftAsset, uint256 nftTokenId, uint256 indexed rewardAmount);

    function createLoan(address initiator, address nftAsset, uint256 nftTokenId, uint256 rewardAmount) external returns(uint256);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns(uint256);

    function getLoan(uint256 loanId) external view returns(DataTypes.LoanData memory);
}
