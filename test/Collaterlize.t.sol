// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {DataTypes} from "../contracts/libraries/types/DataTypes.sol";

contract CollaterlizeTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }

    function testCollateralize() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        vm.stopPrank();

        vm.startPrank(richer2);
        IERC721(BAYC).approve(address(collateralPool), 5904);
        collateralPool.collateralize(BAYC, 5904);
        vm.stopPrank();
        
        _checkCreateLoan();
    }

    function testRevertWithNotBAYC() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        vm.expectRevert("NFT asset is not BAYC");
        collateralPool.collateralize(AZUKI, 7737);
        vm.stopPrank();
    }

    function testRevertWithAlreadyCollateralize() public {
        vm.startPrank(richer1);
        collateralPool.collateralize(BAYC, 7737);
        vm.expectRevert("Nft already collateralized");
        collateralPool.collateralize(BAYC, 7737);
        vm.stopPrank();
    }

    function _checkCreateLoan() internal {
        uint256 loanId1 = collateralPoolLoan.getCollateralLoanId(BAYC, 7737);
        DataTypes.LoanData memory loanData = collateralPoolLoan.getLoan(loanId1);
        uint256 currentPrice = uint256(nftOracle.getLatestPrice());
        uint256 collateralFactor = handler.getCollateralFactor();

        assertEq(loanId1, 1);
        assertEq(loanData.initiator, richer1);
        assertEq(loanData.nftAsset, BAYC);
        assertEq(loanData.nftTokenId, 7737);
        assertEq(loanData.rewardAmount, currentPrice * collateralFactor / 1e18);
    }
}
