// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SToken} from "../../protocol/SToken.sol";
import {NFTOracle} from "../../protocol/NFTOracle.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ICollateralPoolLoan} from "../../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolHandler} from "../../interfaces/ICollateralPoolHandler.sol";
import {ICollateralPoolAddressesProvider} from "../../interfaces/ICollateralPoolAddressesProvider.sol";

library CollateralizeLogic {
    // mainnet BAYC Address
    address public constant BAYCAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    // Sepolia BAYC Address
    address public constant SBAYCAddress = 0xaa6f57b90099f5fC8D30CE44f451E2d00548bcB3;
    // Holesky Fake BAYC Address
    address public constant HBAYCAddress = 0xBf1265D530c15542Cd9804cd8EB47a4C2e2C00f2;

    struct ExecuteCollateralizeLocalVars {
        address initiator;
        address loanAddress;
        address handler;
        address nftOracle;
        uint256 currentPrice;
        uint256 rewardAmount;
        uint256 loanId;
    }

    struct ExecuteRepayLocalVars {
        address initiator;
        address loanAddress;
        address handler;
        uint256 repayAmount;
        uint256 loanId;
    }

    event Collateralize(
        address user,
        address nftAsset,
        uint256 nftTokenId,
        uint256 sTokenAmount,
        uint256 loanId
    );

    event Repay(
        address user,
        uint256 repayAmount,
        uint256 loanId
    );

    function executeCollateralize(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteCollateralizeParams memory params
    ) external {
        ExecuteCollateralizeLocalVars memory vars;
        vars.initiator = params.initiator;
        vars.loanAddress = addressesProvider.getCollateralPoolLoan();
        vars.handler = addressesProvider.getCollateralPoolHandler();
        vars.nftOracle = addressesProvider.getNftOracle();
        vars.loanId = ICollateralPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);

        require(ICollateralPoolHandler(vars.handler).isBlueChipNFT(params.nftAsset), "Not Blue chip NFT asset");
        require(vars.loanId == 0, "NFT already collateralized");

        vars.currentPrice = uint256(NFTOracle(vars.nftOracle).getLatestPrice());     
        // Calculate reward amount
        uint256 collateralFactor = ICollateralPoolHandler(vars.handler).getCollateralFactor();
        vars.rewardAmount = (vars.currentPrice * collateralFactor) / 1e18;

        vars.loanId = ICollateralPoolLoan(vars.loanAddress).createLoan(vars.initiator, params.nftAsset, params.nftTokenId, vars.rewardAmount, 0);
        // Collateralizer transfer NFT to pool, and the pool mints sToken to collateralizer
        IERC721(params.nftAsset).safeTransferFrom(vars.initiator,address(this),params.nftTokenId);
        sToken.mint(vars.initiator, vars.rewardAmount);

        emit Collateralize(
            vars.initiator,
            params.nftAsset,
            params.nftTokenId,
            vars.rewardAmount,
            vars.loanId
        );
    }

    function executeRepay(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteRepayParams memory params
    ) external {
        ExecuteRepayLocalVars memory vars;
        vars.initiator = params.initiator;
        vars.repayAmount = params.repayAmount + msg.value;
        vars.loanAddress = addressesProvider.getCollateralPoolLoan();
        vars.handler = addressesProvider.getCollateralPoolHandler();
        
        vars.loanId = ICollateralPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);
        require(vars.loanId != 0, "NFT is not collateral");
        require(vars.repayAmount != 0, "Repay amount must be greater than 0");
        ICollateralPoolLoan(vars.loanAddress).updateLoan(vars.initiator, vars.loanId, vars.repayAmount);

        sToken.transferFrom(vars.initiator, address(this), params.repayAmount);

        emit Repay(
            vars.initiator,
            vars.repayAmount,
            vars.loanId
        );
    }
}
