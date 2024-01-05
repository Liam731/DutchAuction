// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPool} from "../interfaces/ICollateralPool.sol";
import {ICollateralPoolLoan} from "../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract CollateralPoolLoan is ICollateralPoolLoan {
    uint256 private _loanId;
    mapping(uint256 => DataTypes.LoanData) private _loanIds;
    mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
    bool private _initialized;
    ICollateralPoolAddressesProvider private _addressesProvider;

    modifier onlyCollateralPool() {
        require(address(_getCollateralPool()) == msg.sender, "Caller must be collateral pool");
        _;
    }

    function initialize(ICollateralPoolAddressesProvider provider) external {
        require(!_initialized, "Already initialized");
        _addressesProvider = provider;
        _initialized = true;

        emit Initialized(address(provider));
    }

    function createLoan(address initiator, address nftAsset, uint256 nftTokenId, uint256 rewardAmount) external onlyCollateralPool returns(uint256){
        _loanId++;
        _nftToLoanIds[nftAsset][nftTokenId] = _loanId;
        // Save Info
        DataTypes.LoanData storage loanData = _loanIds[_loanId];
        loanData.initiator = initiator;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.rewardAmount = rewardAmount;

        emit LoanCreated(initiator, _loanId, nftAsset, nftTokenId, rewardAmount);

        return _loanId;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns(uint256) {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getLoan(uint256 loanId) external view returns(DataTypes.LoanData memory) {
        return _loanIds[loanId];
    }

    function _getCollateralPool() internal view returns(ICollateralPool) {
        return ICollateralPool(_addressesProvider.getCollateralPool());
    }
}