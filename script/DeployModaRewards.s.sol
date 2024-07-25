// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";

contract DeployModaRewards is Script {
    function run() public {
        address owner = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address cmkStakingContract = vm.envAddress("STAKING_CONTRACT");
        address supporterToken = vm.envAddress("MODA_TOKEN");

        vm.startBroadcast(privateKey);

        uint256 initialBurnCost = 1_000 ether;
        uint256 burnCostIncrement = 100 ether;
        uint256 initialStakeCost = 1_000 ether;
        uint256 stakeCostIncrement = 100 ether;
        uint256 totalAllocation = 2_000 ether;

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

        console.log("MODA SupporterRewards deployed at:", address(supporterRewards));

        vm.stopBroadcast();
    }
}
