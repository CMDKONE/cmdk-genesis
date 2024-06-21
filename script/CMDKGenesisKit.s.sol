// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";

contract CMDKGenesisKitScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address releaseAdmin = vm.envAddress("RELEASE_ADMIN");
        vm.startBroadcast(privateKey);

        CMDKGenesisKit cmdkGenesisKit = new CMDKGenesisKit();

        console.log("CMDKGenesisKit deployed at:", address(cmdkGenesisKit));

        vm.stopBroadcast();
    }
}
