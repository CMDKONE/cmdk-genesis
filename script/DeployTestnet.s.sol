// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {TestnetFaucet} from "../src/TestnetFaucet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployTestnet is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(privateKey);

        // Tokens
        CMDKGenesisKit cmk404Token = new CMDKGenesisKit(owner);

        // Allocate metadata to CMDKGenesisKit
        cmk404Token.setBaseURI("ipfs://QmPa35cRFPeHbZztgxJ9gGie7BzjTEG9vWZpubiJRqF2Cn");
        cmk404Token.setContractURI("ipfs://QmZgzS1kd7gBsp7tzGtV9bvEJe93bHGFqnDfjXsPdLWfks");

        // Staking Contract
        StakingRewards stakingRewards = StakingRewards(
            Upgrades.deployTransparentProxy(
                "StakingRewards.sol", owner, abi.encodeCall(StakingRewards.initialize, (owner, address(cmk404Token)))
            )
        );

        TestnetFaucet testnetFaucet = new TestnetFaucet();
        cmk404Token.transfer(address(testnetFaucet), 1_000);

        console.log("CMDK Genesis Kit deployed at:", address(cmk404Token));
        console.log("CMK404 StakingRewards deployed at:", address(stakingRewards));
        console.log("Testnet Faucet deployed at:", address(testnetFaucet));

        vm.stopBroadcast();
    }
}
