// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ClaimAndStake} from "../src/ClaimAndStake.sol";

contract DeployClaimAndStake is Script {
    function run() public {
        address owner = vm.envAddress("DEPLOYER_ADDRESS");
        address tokenAddress = vm.envAddress("ONE404_TOKEN_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        ClaimAndStake claimAndStake = new ClaimAndStake(owner, tokenAddress);

        console.log("ClaimAndStake deployed at:", address(claimAndStake));

        vm.stopBroadcast();
    }
}
