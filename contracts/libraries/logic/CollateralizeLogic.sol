// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SToken} from "../../protocol/SToken.sol";
import {NFTOracle} from "../../protocol/NFTOracle.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ICollateralPoolLoan} from "../../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolAddressesProvider} from "../../interfaces/ICollateralPoolAddressesProvider.sol";

library CollateralizeLogic {
    //Goerli BAYC Address
    address public constant BAYCAddress = 0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;

    struct ExecuteCollateralizeLocalVars {
        address initiator;
        uint256 coinAmount;
        address nftOracle;
        uint256 loanId;
        address loanAddress;
    }

    event Collateralize(
        address user,
        address nftAsset,
        uint256 nftTokenId,
        uint256 sTokenAmount,
        uint256 loanId
    );

    function executeCollateralize(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteCollateralizeParams memory params
    ) external {
        _collateralize(addressesProvider, sToken, params);
    }

    function _collateralize(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken,
        DataTypes.ExecuteCollateralizeParams memory params
    ) internal {
        require(params.nftAsset == BAYCAddress, "The collateralized NFT asset is not BAYC");

        ExecuteCollateralizeLocalVars memory vars;
        vars.initiator = params.initiator;
        vars.loanAddress = addressesProvider.getCollateralPoolLoan();

        vars.loanId = ICollateralPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);
        require(vars.loanId == 0, "Nft already collateralized");

        vars.loanId = ICollateralPoolLoan(vars.loanAddress).createLoan(vars.initiator, params.nftAsset, params.nftTokenId);
        // Transfer NFT
        IERC721(params.nftAsset).safeTransferFrom(vars.initiator,address(this),params.nftTokenId);
        vars.nftOracle = addressesProvider.getNftOracle();
        int nftPrice = NFTOracle(vars.nftOracle).getLatestPrice();
        //collateral factor = 60%
        vars.coinAmount = (uint256(nftPrice) * 6) / 10;
        sToken.mint(vars.initiator, vars.coinAmount);

        emit Collateralize(
            vars.initiator,
            params.nftAsset,
            params.nftTokenId,
            vars.coinAmount,
            vars.loanId
        );
    }
}
