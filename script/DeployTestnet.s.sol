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
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");

        vm.startBroadcast(privateKey);

        // CMDK TOKEN
        CMDKLaunchKit cmdkLaunchKit = new CMDKLaunchKit(owner, "Test ERC404", "$T404");

        // Claim and Stake contract
        ClaimAndStake claimAndStake = new ClaimAndStake(owner, address(cmdkLaunchKit));
        claimAndStake.setMerkleRoot(merkleRoot);
        claimAndStake.setUnstakeEnabled(true);

        // Faucet contract
        Faucet faucet = new Faucet(address(cmdkLaunchKit));

        // Give out allocation
        cmdkLaunchKit.transfer(address(claimAndStake), 1000 ether);
        cmdkLaunchKit.transfer(address(faucet), 1000 ether);

        console.log('export const FAUCET_ADDRESS: `0x${string}` = "', address(faucet), '";');
        console.log('export const ONE404_TOKEN_ADDRESS: `0x${string}` = "', address(cmdkLaunchKit), '";');
        console.log('export const CLAIM_CONTRACT_ADDRESS: `0x${string}` = "', address(claimAndStake), '";');

        vm.stopBroadcast();
    }
}
