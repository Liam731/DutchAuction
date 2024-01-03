// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { CollateralizeSetUp } from "./helper/CollaterlizeSetup.sol";
import { console } from "forge-std/console.sol";
import { PunkWarriorErc721, ERC721, IERC721 } from "../contracts/PunkWarriorErc721.sol";
import { NFTOracle } from "../contracts/protocol/NFTOracle.sol";
import { CollateralPool } from "../contracts/protocol/CollateralPool.sol";
import { CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider } from "../contracts/protocol/CollateralPoolAddressesProvider.sol";
import { SToken } from "../contracts/protocol/SToken.sol";


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
        address OracleOfBAYC = CPAP.getAddress(NFT_ORACLE);
        assertEq(OracleOfBAYC,chainlinkOracle);        
    }

    function testCollateralize() public {
        address richer = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
        vm.startPrank(richer);

        IERC721(BAYC).approve(address(collateralPool), 7737);
        collateralPool.collateralize(BAYC, 7737);

        vm.stopPrank();
    }

    function testRevertCollateralize() public {
        address richer = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
        address AZUKI = 0x10B8b56D53bFA5e374f38e6C0830BAd4ebeE33E6;
        vm.startPrank(richer);
        IERC721(BAYC).approve(address(collateralPool), 7737);
        vm.expectRevert("The collateralized NFT asset is not BAYC");
        collateralPool.collateralize(AZUKI, 7737);
        
        vm.stopPrank();
    }

}
