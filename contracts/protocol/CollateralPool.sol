// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ICollateralPool} from "../interfaces/ICollateralPool.sol";
import {ICollateralPoolAddressesProvider} from "../interfaces/ICollateralPoolAddressesProvider.sol";
import {SToken} from "./SToken.sol";

import {CollateralizeLogic} from "../libraries/logic/CollateralizeLogic.sol";
import {LiquidateLogic} from "../libraries/logic/LiquidateLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CollateralPoolStorage} from "./CollateralPoolStorage.sol";

contract CollateralPool is ICollateralPool, CollateralPoolStorage, IERC721Receiver {
    constructor(){
        _admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(_admin == msg.sender, "Only admin can call this function");
        _;
    }

    function initialize(ICollateralPoolAddressesProvider provider,SToken sToken) external onlyAdmin {
        require(!_initialized, "Already initialized");
        _addressesProvider = provider;
        _sToken = sToken;
        _initialized = true;

        emit Initialized(address(provider));
    }

    function collateralize(address nftAsset, uint256 nftTokenId) external override {
        CollateralizeLogic.executeCollateralize(
            _addressesProvider,
            _sToken,
            DataTypes.ExecuteCollateralizeParams({
                initiator: msg.sender,
                nftAsset: nftAsset,
                nftTokenId: nftTokenId
            })
        );
    }

    function redeem(address nftAsset, uint256 nftTokenId) external payable override returns(uint256) {
        return
            LiquidateLogic.executeRedeem(
                _addressesProvider,
                _sToken,
                DataTypes.ExecuteRedeemParams({
                    initiator: msg.sender,
                    nftAsset: nftAsset,
                    nftTokenId: nftTokenId
                })
            );
    }
    function addToWhitelist(address actionAddress) external onlyAdmin {
        whitelist[actionAddress] = true;
    }

    function removeFromWhitelist(address actionAddress) external onlyAdmin {
        whitelist[actionAddress] = false;
    }

    function isWhitelisted(address actionAddress) external view returns (bool) {
        return whitelist[actionAddress];
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
