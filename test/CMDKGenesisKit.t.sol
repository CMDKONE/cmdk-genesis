// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";

contract CMDKGenesisKitTest is Test {
    CMDKGenesisKit public cmdkGenesisKit;

    function setUp() public {
        cmdkGenesisKit = new CMDKGenesisKit();
    }

    function test_name() public view {
        assertEq(cmdkGenesisKit.name(), "CMDK Genesis Kit");
    }

    function test_symbol() public view {
        assertEq(cmdkGenesisKit.symbol(), "$CMK404");
    }

    function test_totalSupply() public view {
        assertEq(cmdkGenesisKit.totalSupply(), (10_000) * 10 ** 18);
    }
}
