// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SupporterToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1_000_000_000 * 10 ** 18);
    }
}

contract DeployTestnet is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(privateKey);

        // Tokens
        SupporterToken modaToken = new SupporterToken("MODA", "MODA");
        SupporterToken emtToken = new SupporterToken("EMT", "EMT");
        CMDKGenesisKit cmdkGenesisKit = new CMDKGenesisKit(owner);

        // Staking Contract
        StakingRewards stakingRewards = StakingRewards(
            Upgrades.deployTransparentProxy(
                "StakingRewards.sol",
                owner,
                abi.encodeCall(StakingRewards.initialize, (owner, address(cmdkGenesisKit)))
            )
        );

        // Supporter Rewards for MODA and EMT
        SupporterRewards modaRewards = SupporterRewards(
            Upgrades.deployTransparentProxy(
                "SupporterRewards.sol",
                owner,
                abi.encodeCall(
                    SupporterRewards.initialize,
                    (
                        owner,
                        address(modaToken),
                        1_000 ether,
                        100 ether,
                        2_000 ether,
                        address(stakingRewards)
                    )
                )
            )
        );
        SupporterRewards emtRewards = SupporterRewards(
            Upgrades.deployTransparentProxy(
                "SupporterRewards.sol",
                owner,
                abi.encodeCall(
                    SupporterRewards.initialize,
                    (
                        owner,
                        address(emtToken),
                        1_000 ether,
                        100 ether,
                        500 ether,
                        address(stakingRewards)
                    )
                )
            )
        );
        // Grant roles for staking
        stakingRewards.grantRole(keccak256("SUPPORTER_ROLE"), address(modaRewards));
        stakingRewards.grantRole(keccak256("SUPPORTER_ROLE"), address(emtRewards));

        console.log("MODA Token deployed at:", address(modaToken));
        console.log("EMT Token deployed at:", address(emtToken));
        console.log("CMDK Genesis Kit deployed at:", address(cmdkGenesisKit));
        console.log("MODA SupporterRewards deployed at:", address(modaRewards));
        console.log("EMT SupporterRewards deployed at:", address(emtRewards));

        vm.stopBroadcast();
    }
}
