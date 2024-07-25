// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";

contract DeployEmtRewards is Script {
    function run() public {
        address owner = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address cmkStakingContract = vm.envAddress("STAKING_CONTRACT");
        address supporterToken = vm.envAddress("EMT_TOKEN");

        vm.startBroadcast(privateKey);

        uint256 initialBurnCost = 1_000 ether;
        uint256 burnCostIncrement = 100 ether;
        uint256 initialStakeCost = 1_000 ether;
        uint256 stakeCostIncrement = 100 ether;
        uint256 totalAllocation = 500 ether;

        bytes memory initializerData = abi.encodeCall(
            SupporterRewards.initialize,
            (
                owner,
                supporterToken,
                initialBurnCost,
                burnCostIncrement,
                initialStakeCost,
                stakeCostIncrement,
                totalAllocation,
                cmkStakingContract
            )
        );
        SupporterRewards supporterRewards = SupporterRewards(
            Upgrades.deployTransparentProxy("SupporterRewards.sol", owner, initializerData)
        );

        console.log("EMT SupporterRewards deployed at:", address(supporterRewards));

        vm.stopBroadcast();
    }
}
