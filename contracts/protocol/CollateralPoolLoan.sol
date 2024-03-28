// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ICollateralPool} from "../interfaces/ICollateralPool.sol";
import {ICollateralPoolLoan} from "../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolHandler} from "../interfaces/ICollateralPoolHandler.sol";
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";
import {NFTOracle} from "./NFTOracle.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract CollateralPoolLoan is ICollateralPoolLoan {
    uint256 private _loanId;
    mapping(address => uint256[]) private _loanTokenList;
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

    function createLoan(address initiator, address nftAsset, uint256 nftTokenId, uint256 rewardAmount, uint256 repayAmount) external override onlyCollateralPool returns(uint256){
        _loanId++;
        _nftToLoanIds[nftAsset][nftTokenId] = _loanId;
        // Save Info
        DataTypes.LoanData storage loanData = _loanIds[_loanId];
        loanData.initiator = initiator;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.rewardAmount = rewardAmount;
        loanData.repayAmount = repayAmount;

        _loanTokenList[initiator].push(nftTokenId);
        emit LoanCreated(initiator, _loanId, nftAsset, nftTokenId, rewardAmount);

        return _loanId;
    }

    function updateLoan(address initiator, uint256 loanId, uint256 repayAmount) external override returns(uint256){
        // Must use storage to change state
        DataTypes.LoanData storage loanData = _loanIds[loanId];
        loanData.repayAmount = repayAmount;

        emit LoanUpdated(initiator, loanId, repayAmount);
        return loanId;
    }

    function deleteLoan(address initiator, address nftAsset, uint256 nftTokenId) external override {
        // Initialize asset loan
        _nftToLoanIds[nftAsset][nftTokenId] = 0; 
        uint256[] storage tokens = _loanTokenList[initiator];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == nftTokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) public view override returns(uint256) {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getLoan(uint256 loanId) public view override returns(DataTypes.LoanData memory) {
        return _loanIds[loanId];
    }

    function getPersonalLoanTokenList(address account) external view override returns(uint256[] memory) {
        return _loanTokenList[account];
    }

    function getNftAssetHealthFactor(address nftAsset, uint256 nftTokenId) external view override returns(uint256) {
        uint256 loanId = getCollateralLoanId(nftAsset, nftTokenId);
        require(loanId != 0, "NFT is not collateral");
        address nftOracle = _addressesProvider.getNftOracle();
        address handler = _addressesProvider.getCollateralPoolHandler();
        uint256 liquidateFactor = ICollateralPoolHandler(handler).getLiquidateFactor();

        uint256 currentPrice = uint256(NFTOracle(nftOracle).getLatestPrice());        
        DataTypes.LoanData memory loanData = getLoan(loanId);
        uint256 liquidationThreshole = currentPrice + loanData.repayAmount;

        uint256 healthFactor = (liquidationThreshole * liquidateFactor)  / loanData.rewardAmount;

        return healthFactor;
    }

    function _getCollateralPool() internal view returns(ICollateralPool) {
        return ICollateralPool(_addressesProvider.getCollateralPool());
    }
}