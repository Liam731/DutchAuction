// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SToken} from "../../protocol/SToken.sol";
import {NFTOracle} from "../../protocol/NFTOracle.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ICollateralPoolAddressesProvider} from "../../interfaces/ICollateralPoolAddressesProvider.sol";

library CollateralizeLogic {
    //Goerli BAYC Address
    address public constant BAYCAddress =
        0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;

    struct ExecuteCollateralizeLocalVars {
        address initiator;
        uint256 coinAmount;
        address nftOracle;
    }

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
        vars.initiator = params.collateralProvider;

        IERC721(params.nftAsset).safeTransferFrom(vars.initiator,address(this),params.nftTokenId);
        vars.nftOracle = addressesProvider.getNFTOracle();
        int nftPrice = NFTOracle(vars.nftOracle).getLatestPrice();
        //collateral factor = 60%
        vars.coinAmount = (uint256(nftPrice) * 6) / 10;
        sToken.mint(vars.initiator, vars.coinAmount);
        // IBToken(reserveData.bTokenAddress).transferUnderlyingTo(vars.initiator, params.amount);
    }
}
