// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {PunkWarriorErc721} from "../../contracts/PunkWarriorErc721.sol";
import {NFTOracle} from "../../contracts/protocol/NFTOracle.sol";
import {CollateralPool} from "../../contracts/protocol/CollateralPool.sol";
import {CollateralPoolLoan} from "../../contracts/protocol/CollateralPoolLoan.sol";
import {CollateralPoolHandler,ICollateralPoolHandler} from "../../contracts/protocol/CollateralPoolHandler.sol";
import {CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider} from "../../contracts/protocol/CollateralPoolAddressesProvider.sol";
import {SToken} from "../../contracts/protocol/SToken.sol";
import {DataTypes} from "../../contracts/libraries/types/DataTypes.sol";

contract GeneralSetUp is Test {

    address public constant admin = 0x1D36536728a32B5A9511E20cdc7eBA6DD4e3A253;
    address public constant richer1 = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
    address public constant richer2 = 0x5647B3FA9951152EED082969C4677A3B06cdB3a7;
    address public constant BAYC = 0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;
    address public constant AZUKI = 0x10B8b56D53bFA5e374f38e6C0830BAd4ebeE33E6;
    address public constant chainlinkOracle = 0xEb1C76Fb7A575D2b2016e99221eB4B0BC43cD3bd;
    address public user1;
    CollateralPool public collateralPool;
    CollateralPoolLoan public collateralPoolLoan;
    CollateralPoolHandler public handler;
    CollateralPoolAddressesProvider public addressesProvider;
    PunkWarriorErc721 public erc721;
    SToken public sToken;
    bytes32 public constant NFT_ORACLE = "NFT_ORACLE";
    bytes32 public constant COLLATERAL_POOL = "COLLATERAL_POOL";
    bytes32 public constant COLLATERAL_POOL_LOAN = "COLLATERAL_POOL_LOAN";
    bytes32 public constant COLLATERAL_POOL_HANDLER = "COLLATERAL_POOL_HANDLER";

    NFTOracle public nftOracle;

    function setUp() public virtual{
        vm.createSelectFork(vm.envString("GOERLI_RPC_RUL"));
        user1 = makeAddr("User1");
        vm.deal(user1, 100 ether);
        vm.startPrank(admin);
        // Depoly collateral pool addresses provider
        addressesProvider = new CollateralPoolAddressesProvider();
        // Depoly collateral pool with sToken
        collateralPool = new CollateralPool();
        sToken = new SToken(address(collateralPool));
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        vm.deal(address(collateralPool), 100 ether);
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
        // Punk warrior set as whitelist
        collateralPool.addToWhitelist(address(erc721));
        vm.stopPrank();
    }

}