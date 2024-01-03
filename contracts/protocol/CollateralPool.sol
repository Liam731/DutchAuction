// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {CollateralizeLogic} from "../libraries/logic/CollateralizeLogic.sol";
import {CollateralPoolStorage} from "./CollateralPoolStorage.sol";
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SToken} from "./SToken.sol";

contract CollateralPool is CollateralPoolStorage, IERC721Receiver {
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function initialize(
        ICollateralPoolAddressesProvider addressesProvider,
        SToken sToken
    ) external {
        _addressesProvider = addressesProvider;
        _sToken = sToken;
    }

    function collateralize(address nftAsset, uint256 nftTokenId) external {
        CollateralizeLogic.executeCollateralize(
            _addressesProvider,
            _sToken,
            DataTypes.ExecuteCollateralizeParams({
                collateralProvider: msg.sender,
                nftAsset: nftAsset,
                nftTokenId: nftTokenId
            })
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
    }
}
