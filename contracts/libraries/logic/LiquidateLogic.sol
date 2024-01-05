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
        address nftAsset,
        uint256 indexed nftTokenId,
        uint256 loanId
    );
    struct RedeemLocalVars {
        address initiator;
        address poolLoan;
        address nftOracle;
        uint256 loanId;
        uint256 repayAmount;
    }

    function executeRedeem(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteRedeemParams memory params
    ) external returns (uint256) {
        RedeemLocalVars memory vars;
        vars.initiator = params.initiator;

        vars.poolLoan = addressesProvider.getCollateralPoolLoan();

        vars.loanId = ICollateralPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
        require(vars.loanId != 0, "NFT is not collateral");

        DataTypes.LoanData memory loanData = ICollateralPoolLoan(vars.poolLoan).getLoan(vars.loanId);
        require(loanData.initiator == vars.initiator, "Not NFT owner");

        vars.repayAmount = loanData.rewardAmount;
        uint256 initiatorBalance = sToken.balanceOf(vars.initiator);
        require(initiatorBalance + msg.value >= vars.repayAmount, "Not enough balance for redeem");
        if(initiatorBalance >= vars.repayAmount) {
            sToken.transferFrom(vars.initiator, address(this), vars.repayAmount);
        } else {
            sToken.transferFrom(vars.initiator, address(this), initiatorBalance);
        }
        
        IERC721(params.nftAsset).safeTransferFrom(address(this), vars.initiator ,params.nftTokenId);

        emit Redeem(
            vars.initiator,
            vars.repayAmount,
            loanData.nftAsset,
            loanData.nftTokenId,
            vars.loanId
        );

        return vars.repayAmount;
    }
}
