// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {PunkWarriorErc721} from "../contracts/PunkWarriorErc721.sol";
import {NFTOracle} from "../contracts/protocol/NFTOracle.sol";
import {CollateralPool} from "../contracts/protocol/CollateralPool.sol";
import {CollateralPoolLoan} from "../contracts/protocol/CollateralPoolLoan.sol";
import {CollateralPoolHandler,ICollateralPoolHandler} from "../contracts/protocol/CollateralPoolHandler.sol";
import {CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider} from "../contracts/protocol/CollateralPoolAddressesProvider.sol";
import {SToken} from "../contracts/protocol/SToken.sol";

contract DeployScript is Script {
    address public constant chainlinkOracle = 0xEb1C76Fb7A575D2b2016e99221eB4B0BC43cD3bd;
    
    CollateralPool public collateralPool;
    CollateralPoolLoan public collateralPoolLoan;
    CollateralPoolHandler public handler;
    CollateralPoolAddressesProvider public addressesProvider;
    NFTOracle public nftOracle;
    PunkWarriorErc721 public erc721;
    SToken public sToken;
    
    bytes32 public constant NFT_ORACLE = "NFT_ORACLE";
    bytes32 public constant COLLATERAL_POOL = "COLLATERAL_POOL";
    bytes32 public constant COLLATERAL_POOL_LOAN = "COLLATERAL_POOL_LOAN";
    bytes32 public constant COLLATERAL_POOL_HANDLER = "COLLATERAL_POOL_HANDLER";

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("DEV_PRIVATE_KEY"));
        // Depoly collateral pool addresses provider
        addressesProvider = new CollateralPoolAddressesProvider();
        // Depoly collateral pool with sToken
        collateralPool = new CollateralPool();
        sToken = new SToken(address(collateralPool));
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        // Deploy collateral pool loan
        collateralPoolLoan = new CollateralPoolLoan();
        collateralPoolLoan.initialize(ICollateralPoolAddressesProvider(addressesProvider));
        // Deploy collateral pool handler
        handler = new CollateralPoolHandler();
        // Set collateral factor = 60%
        ICollateralPoolHandler(handler).setCollateralFactor(60 * 1e16);
        // Set liquidate factor = 75%
        ICollateralPoolHandler(handler).setLiquidateFactor(75 * 1e16);
        // Set liquidation incentive = 10%
        ICollateralPoolHandler(handler).setLiquidationIncentive(10 * 1e16);
        // Deploy NFTOracle
        nftOracle = NFTOracle(chainlinkOracle);
        // Set collateral pool addresses
        addressesProvider.setAddress(NFT_ORACLE, address(nftOracle));
        addressesProvider.setAddress(COLLATERAL_POOL, address(collateralPool));
        addressesProvider.setAddress(COLLATERAL_POOL_LOAN, address(collateralPoolLoan));
        addressesProvider.setAddress(COLLATERAL_POOL_HANDLER, address(handler));
        // Depoly PunkWarriorErc721 with DutchAuction
        erc721 = new PunkWarriorErc721();
        erc721.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        erc721.setBaseURI("ipfs://QmfE1NWNVKtz7KaP2Ussz8xWcds6objCTekK6evn413eXh/1.json");
        vm.stopBroadcast();
        console2.log("addressesProvider = ", address(addressesProvider));
        console2.log("collateralPool = ", address(collateralPool));
        console2.log("collateralPoolLoan = ", address(collateralPoolLoan));
        console2.log("handler = ", address(handler));
        console2.log("nftOracle = ", address(nftOracle));
        console2.log("warriorNFT = ", address(erc721));
        console2.log("sToken = ", address(sToken));
    }
}
