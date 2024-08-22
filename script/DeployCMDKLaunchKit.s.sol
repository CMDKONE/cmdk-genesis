// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {CMDKLaunchKit} from "../src/CMDKLaunchKit.sol";

contract DeployCMDKLaunchKit is Script {
    function run() public {
        address owner = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        CMDKLaunchKit cmdkLaunchKit = new CMDKLaunchKit(owner);

        console.log("CMDKLaunchKit deployed at:", address(cmdkLaunchKit));

        vm.stopBroadcast();
    }
}
