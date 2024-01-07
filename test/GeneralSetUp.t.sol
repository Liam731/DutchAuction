// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {GeneralSetUp} from "./helper/GeneralSetUp.sol";

contract RedeemTest is GeneralSetUp {
    
    function setUp() public override {
    }
    
    function testGeneralSetUp() public {
        GeneralSetUp generalSetUp = new GeneralSetUp();
        generalSetUp.setUp();
    }
}