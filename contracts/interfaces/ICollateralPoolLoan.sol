// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ICollateralPoolLoan {
    /**
     * @dev Emitted on initialization to share location of dependent notes
     * @param pool The address of the associated Collateral pool
     */
    event Initialized(address indexed pool);

    /**
     * @dev Emitted when a loan is created
     * @param user The address initiating the action
     */
    event LoanCreated(address indexed user, uint256 indexed loanId, address nftAsset, uint256 nftTokenId, uint256 rewardAmount);
    
    function createLoan(address initiator, address nftAsset, uint256 nftTokenId, uint256 rewardAmount) external returns(uint256);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns(uint256);

    function getLoan(uint256 loanId) external view returns(DataTypes.LoanData memory);
}
