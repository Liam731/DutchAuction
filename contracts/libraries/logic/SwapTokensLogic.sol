// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SToken} from "../../protocol/SToken.sol";
import {NFTOracle} from "../../protocol/NFTOracle.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ICollateralPoolLoan} from "../../interfaces/ICollateralPoolLoan.sol";
import {ICollateralPoolHandler} from "../../interfaces/ICollateralPoolHandler.sol";
import {ICollateralPoolAddressesProvider} from "../../interfaces/ICollateralPoolAddressesProvider.sol";

library SwapTokensLogic {
    event Swap(
        address indexed user,
        uint256 amountIn
    );

    function executeSwap(
        SToken sToken,
        DataTypes.ExecuteSwapParams memory params
    ) external {
        uint256 initiatorBalance = sToken.balanceOf(params.initiator);
        require(initiatorBalance >= params.amountIn, "Not enough balance for swap");
        sToken.burn(params.initiator, params.amountIn);
        (bool success, ) = (params.initiator).call{value: params.amountIn}("");
        require(success, "Swap ETH failed");

        emit Swap(params.initiator, params.amountIn);
    }
}
