// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract EmtRewardsScript is Script {
    function run() public {
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address supporterToken = vm.envAddress("EMT_TOKEN");
        address cmdkToken = vm.envAddress("CMDK_TOKEN");

        vm.startBroadcast(privateKey);

        address beacon = Upgrades.deployBeacon(
            "SupporterRewards.sol:SupporterRewards",
            deployerAddress
        );

        uint256 startBurnPrice = 1000;
        uint256 increaseStep = 100;

        SupporterRewards supporterRewards = SupporterRewards(
            Upgrades.deployBeaconProxy(
                beacon,
                abi.encodeCall(
                    SupporterRewards.initialize,
                    (
                        deployerAddress,
                        supporterToken,
                        cmdkToken,
                        startBurnPrice,
                        increaseStep
                    )
                )
            )
        );

        // TODO: setSkipNFT

        console2.log(
            "EMT SupporterRewards deployed at:",
            address(supporterRewards)
        );

        vm.stopBroadcast();
    }
}
