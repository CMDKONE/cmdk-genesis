// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ClaimAndStake} from "../src/ClaimAndStake.sol";
import {CMDKLaunchKit} from "../src/CMDKLaunchKit.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeployTestnet is Script {
    function run() public {
        address owner = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // CMDK TOKEN
        CMDKLaunchKit cmdkLaunchKit = new CMDKLaunchKit(owner, "Test ERC404", "$T404");
        console.log("CMDKLaunchKit deployed at:", address(cmdkLaunchKit));

        // Claim and Stake contract
        ClaimAndStake claimAndStake = new ClaimAndStake(owner, address(cmdkLaunchKit));
        console.log("ClaimAndStake deployed at:", address(claimAndStake));

        // Faucet contract
        Faucet faucet = new Faucet(address(cmdkLaunchKit));
        console.log("Faucet deployed at:", address(faucet));

        // Give out allocation
        cmdkLaunchKit.transfer(address(claimAndStake), 1000);
        cmdkLaunchKit.transfer(address(faucet), 1000);

        vm.stopBroadcast();
    }
}
