// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SToken} from "../../protocol/SToken.sol";
import {NFTOracle} from "../../protocol/NFTOracle.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ICollateralPoolLoan} from "../../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolAddressesProvider} from "../../interfaces/ICollateralPoolAddressesProvider.sol";

library LiquidateLogic {
    event Redeem(
        address indexed user,
        uint256 indexed repayAmount,
        uint256 indexed repayETH,
        address nftAsset,
        uint256 nftTokenId,
        uint256 loanId
    );

    struct RedeemLocalVars {
        address initiator;
        address poolLoan;
        uint256 loanId;
        uint256 repayAmount;
        uint256 sendETHAmount;
    }

    struct LiquidateLocalVars {
        address initiator;
        address poolLoan;
        address nftOracle;
        uint256 loanId;
        uint256 currentPrice;
        uint256 minCollateralAmount;
        uint256 liquidateAmount;
        uint256 refundAmount;
        uint256 incentiveAmount;
        uint256 sendETHAmount;
    }

    function executeRedeem(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteRedeemParams memory params
    ) external returns (uint256) {
        RedeemLocalVars memory vars;
        vars.initiator = params.initiator;
        vars.sendETHAmount = msg.value;
        vars.poolLoan = addressesProvider.getCollateralPoolLoan();

        vars.loanId = ICollateralPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
        require(vars.loanId != 0, "NFT is not collateral");

        DataTypes.LoanData memory loanData = ICollateralPoolLoan(vars.poolLoan).getLoan(vars.loanId);
        require(loanData.initiator == vars.initiator, "Not NFT owner");

        vars.repayAmount = loanData.rewardAmount;
        uint256 initiatorBalance = sToken.balanceOf(vars.initiator);
        require(initiatorBalance + vars.sendETHAmount >= vars.repayAmount, "Not enough balance for redeem");
        if(initiatorBalance >= vars.repayAmount) {
            sToken.transferFrom(vars.initiator, address(this), vars.repayAmount);
        } else {
            vars.repayAmount = initiatorBalance;
            sToken.transferFrom(vars.initiator, address(this), vars.repayAmount);
        }
        
        IERC721(params.nftAsset).safeTransferFrom(address(this), vars.initiator ,params.nftTokenId);

        emit Redeem(
            vars.initiator,
            vars.repayAmount,
            vars.sendETHAmount,
            loanData.nftAsset,
            loanData.nftTokenId,
            vars.loanId
        );

        return vars.repayAmount;
    }

    function executeLiquidate(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteLiquidateParams memory params
    ) external {
        LiquidateLocalVars memory vars;
        vars.initiator = params.initiator;
        vars.sendETHAmount = msg.value;

        vars.nftOracle = addressesProvider.getNftOracle();
        int nftPrice = NFTOracle(vars.nftOracle).getLatestPrice();
        vars.currentPrice = uint256(nftPrice);
        vars.poolLoan = addressesProvider.getCollateralPoolLoan();

        vars.loanId = ICollateralPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
        require(vars.loanId != 0, "NFT is not collateral");

        DataTypes.LoanData memory loanData = ICollateralPoolLoan(vars.poolLoan).getLoan(vars.loanId);
        vars.minCollateralAmount = loanData.rewardAmount * 75 / 60;
        require(vars.currentPrice < vars.minCollateralAmount, "NFT floor price too high, liquidation cannot be executed");
        vars.liquidateAmount = vars.currentPrice * 9 / 10;
        vars.incentiveAmount = vars.currentPrice * 1 / 10;
        require(vars.sendETHAmount > vars.liquidateAmount, "Not enough balance for liquidation");
        // Refund ETH to the collateralizer
        uint256 collateralizerBalance = sToken.balanceOf(loanData.initiator);
        if(loanData.rewardAmount > collateralizerBalance){
            vars.refundAmount = vars.liquidateAmount - (loanData.rewardAmount - collateralizerBalance);
            sToken.burn(loanData.initiator, collateralizerBalance);
        }else{
            vars.refundAmount = vars.liquidateAmount;
            sToken.burn(loanData.initiator, loanData.rewardAmount);   
        }
        (bool success, ) = loanData.initiator.call{value: vars.refundAmount}("");
        require(success, "Refund ETH failed");
        // sToken.transferFrom(vars.initiator, address(this), vars.liquidateAmount);
        IERC721(params.nftAsset).safeTransferFrom(address(this), vars.initiator ,params.nftTokenId);
    }
}
