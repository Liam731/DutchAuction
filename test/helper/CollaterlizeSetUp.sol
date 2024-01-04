// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {PunkWarriorErc721, ERC721, IERC721} from "../../contracts/PunkWarriorErc721.sol";
import {NFTOracle} from "../../contracts/protocol/NFTOracle.sol";
import {CollateralPool} from "../../contracts/protocol/CollateralPool.sol";
import {CollateralPoolLoan} from "../../contracts/protocol/CollateralPoolLoan.sol";
import {CollateralPoolAddressesProvider,ICollateralPoolAddressesProvider} from "../../contracts/protocol/CollateralPoolAddressesProvider.sol";
import {SToken} from "../../contracts/protocol/SToken.sol";
import {DataTypes} from "../../contracts/libraries/types/DataTypes.sol";

contract CollateralizeSetUp is Test {

    address public constant admin = 0x1D36536728a32B5A9511E20cdc7eBA6DD4e3A253;
    address public constant richer1 = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
    address public constant richer2 = 0x5647B3FA9951152EED082969C4677A3B06cdB3a7;
    address public constant BAYC = 0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;
    address public constant AZUKI = 0x10B8b56D53bFA5e374f38e6C0830BAd4ebeE33E6;
    address public constant chainlinkOracle = 0xEb1C76Fb7A575D2b2016e99221eB4B0BC43cD3bd;
    CollateralPool public collateralPool;
    CollateralPoolLoan public collateralPoolLoan;
    CollateralPoolAddressesProvider public addressesProvider;
    PunkWarriorErc721 public erc721;
    SToken public sToken;
    bytes32 public constant NFT_ORACLE = "NFT_ORACLE";
    bytes32 public constant COLLATERAL_POOL = "COLLATERAL_POOL";
    bytes32 public constant COLLATERAL_POOL_LOAN = "COLLATERAL_POOL_LOAN";

    NFTOracle public nftOracle;

    function setUp() public virtual{
        vm.createSelectFork(vm.envString("GOERLI_RPC_RUL"));
        
        vm.startPrank(admin);
        // Depoly collateral pool addresses provider
        addressesProvider = new CollateralPoolAddressesProvider();
        // Depoly collateral pool
        collateralPool = new CollateralPool();
        sToken = new SToken(address(collateralPool));
        collateralPool.initialize(ICollateralPoolAddressesProvider(addressesProvider), sToken);
        // Deploy collateral pool loan
        collateralPoolLoan = new CollateralPoolLoan();
        collateralPoolLoan.initialize(ICollateralPoolAddressesProvider(addressesProvider));
        // Set addresses
        addressesProvider.setAddress(NFT_ORACLE,chainlinkOracle);
        addressesProvider.setAddress(COLLATERAL_POOL,address(collateralPool));
        addressesProvider.setAddress(COLLATERAL_POOL_LOAN,address(collateralPoolLoan));
        // Depoly PunkWarriorErc721 with DutchAuction
        erc721 = new PunkWarriorErc721(sToken);
        erc721.setBaseURI("ipfs://QmfE1NWNVKtz7KaP2Ussz8xWcds6objCTekK6evn413eXh/1.json");
        vm.stopPrank();
    }

}