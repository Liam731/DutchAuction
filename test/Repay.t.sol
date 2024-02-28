// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {DataTypes} from "../contracts/libraries/types/DataTypes.sol";

contract RepayTest is GeneralSetUp {
    function setUp() public override {
        super.setUp();
    }

    function testRepay() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(collateralPool), 10 * 1e18);
        (bool success, ) = address(collateralPool).call{value:10 ether}(abi.encodeWithSignature("repay(address,uint256,uint256)", BAYC, 7737, 10 * 1e18));
        require(success);
        vm.stopPrank();
        
        _checkUpdateLoan();
    }

    function testRevertWithInvalidNFT() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(collateralPool), 15 * 1e18);
        vm.expectRevert("NFT is not collateral");
        (bool success, ) = address(collateralPool).call{value:10 ether}(abi.encodeWithSignature("repay(address,uint256,uint256)", BAYC, 0, 15 * 1e18));
        require(success);
        vm.stopPrank();
    }

    function testRevertWithInvalidAmount() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);
        sToken.approve(address(collateralPool), 15 * 1e18);
        vm.expectRevert("Repay amount must be greater than 0");
        collateralPool.repay(BAYC, 7737, 0);
        vm.stopPrank();
    }

    function _checkUpdateLoan() internal {
        uint256 loanId1 = collateralPoolLoan.getCollateralLoanId(BAYC, 7737);
        DataTypes.LoanData memory loanData = collateralPoolLoan.getLoan(loanId1);

        assertEq(loanId1, 1);
        assertEq(loanData.initiator, richer1);
        assertEq(loanData.repayAmount, 20 * 1e18);
    }
}