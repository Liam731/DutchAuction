// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { PunkWarriorErc721, ERC721, IERC721 } from "../../contracts/PunkWarriorErc721.sol";
import { NFTOracle } from "../../contracts/protocol/NFTOracle.sol";
import { CollateralPool } from "../../contracts/protocol/CollateralPool.sol";
import { CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider } from "../../contracts/protocol/CollateralPoolAddressesProvider.sol";
import { SToken } from "../../contracts/protocol/SToken.sol";

contract CollateralizeSetUp is Test {

    address public constant admin = 0x1D36536728a32B5A9511E20cdc7eBA6DD4e3A253;
    address public constant richer = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
    address public constant richer2 = 0x5647B3FA9951152EED082969C4677A3B06cdB3a7;
    address public constant BAYC = 0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;
    address public constant chainlinkOracle = 0xEb1C76Fb7A575D2b2016e99221eB4B0BC43cD3bd;
    CollateralPool public collateralPool;
    CollateralPoolAddressesProvider public CPAP;
    PunkWarriorErc721 public PWDA;
    SToken public sToken;
    bytes32 public constant NFT_ORACLE = "NFT_ORACLE";

    NFTOracle public nftOracle;

    function setUp() public virtual{
        vm.createSelectFork(vm.envString("GOERLI_RPC_RUL"));
        
        vm.startPrank(admin);
        //Depoly collateral pool addresses provider
        CPAP = new CollateralPoolAddressesProvider();
        CPAP.setAddress(NFT_ORACLE,chainlinkOracle);
        //Depoly collateral pool
        collateralPool = new CollateralPool();
        sToken = new SToken(address(collateralPool));
        collateralPool.initialize(ICollateralPoolAddressesProvider(CPAP), sToken);
        //Depoly PunkWarriorErc721 with DutchAuction
        PWDA = new PunkWarriorErc721(sToken);
        PWDA.setBaseURI("ipfs://QmfE1NWNVKtz7KaP2Ussz8xWcds6objCTekK6evn413eXh/1.json");
        vm.stopPrank();
    }

}