// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ICollateralPoolLoan {
    event Initialized(address indexed provider);

    event LoanCreated(address indexed user, uint256 indexed loanId, address nftAsset, uint256 nftTokenId, uint256 indexed rewardAmount);

    event LoanUpdated(address indexed user, uint256 indexed loanId, uint256 indexed repayAmount);

    function createLoan(address initiator, address nftAsset, uint256 nftTokenId, uint256 rewardAmount, uint256 repayAmount) external returns(uint256);

    function updateLoan(address initiator, uint256 loanId, uint256 repayAmount) external returns(uint256);

    function deleteLoan(address initiator, address nftAsset, uint256 nftTokenId) external;

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns(uint256);

    function getLoan(uint256 loanId) external view returns(DataTypes.LoanData memory);

    function getPersonalLoanTokenList(address account) external view returns(uint256[] memory);

    function getNftAssetHealthFactor(address nftAsset, uint256 nftTokenId) external view returns(uint256);
}
