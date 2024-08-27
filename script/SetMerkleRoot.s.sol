// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IClaimAndStake} from "../src/interfaces/IClaimAndStake.sol";
import {Faucet} from "../src/Faucet.sol";

contract SetMerkleRoot is Script {
    function run() public {
        address claimAndStakeAddress = vm.envAddress("CLAIM_AND_STAKE_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");

        vm.startBroadcast(privateKey);

        // Claim and Stake contract
        IClaimAndStake claimAndStake = IClaimAndStake(claimAndStakeAddress);
        claimAndStake.setMerkleRoot(merkleRoot);

        vm.stopBroadcast();
    }
}
