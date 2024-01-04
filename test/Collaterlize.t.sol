// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CollateralizeSetUp} from "./helper/CollaterlizeSetup.sol";
import {console} from "forge-std/console.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {DataTypes} from "../contracts/libraries/types/DataTypes.sol";

contract SimpDutchAuction is CollateralizeSetUp {

    function setUp() public override {
        super.setUp();
    }

    function testNFTOracle() public {
        
        //Deploy NFTOracle
        nftOracle = NFTOracle(chainlinkOracle);
        //Prank admin
        vm.startPrank(admin);        
        //Set Azuki NFT address
        nftOracle.setNftAddress(0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74);
        int AzukiPrice = nftOracle.getLatestPrice();
        console.logInt(AzukiPrice); // 5322735600000000000
        //Set BAYC NFT address
        nftOracle.setNftAddress(0xB677bfBc9B09a3469695f40477d05bc9BcB15F50);
        int BAYCPrice = nftOracle.getLatestPrice(); // 25783014190000000000
        console.logInt(BAYCPrice);
        vm.stopPrank();
    }
    
    function testCollateralPoolAddressesProvider() public {
        address OracleOfBAYC = addressesProvider.getAddress(NFT_ORACLE);
        assertEq(OracleOfBAYC,chainlinkOracle);        
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

    function testRevertCollateralize() public {
        vm.startPrank(richer1);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        vm.expectRevert("The collateralized NFT asset is not BAYC");
        collateralPool.collateralize(AZUKI, 7737);
        
        vm.stopPrank();
    }

    function _checkCreateLoan() internal {
        uint256 loanId1 = collateralPoolLoan.getCollateralLoanId(BAYC, 7737);
        DataTypes.LoanData memory loanData = collateralPoolLoan.getLoan(loanId1);
        assertEq(loanId1, 1);
        assertEq(loanData.initiator, richer1);
        assertEq(loanData.nftAsset, BAYC);
        assertEq(loanData.nftTokenId, 7737);
    }
}
