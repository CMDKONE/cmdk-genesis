// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {TestnetFaucet} from "../src/TestnetFaucet.sol";
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
        CMDKGenesisKit cmk404Token = new CMDKGenesisKit(owner);

        // Allocate metadata to CMDKGenesisKit
        cmk404Token.setBaseURI("ipfs://QmPa35cRFPeHbZztgxJ9gGie7BzjTEG9vWZpubiJRqF2Cn");
        cmk404Token.setContractURI("ipfs://QmZgzS1kd7gBsp7tzGtV9bvEJe93bHGFqnDfjXsPdLWfks");

        // Staking Contract
        StakingRewards stakingRewards = StakingRewards(
            Upgrades.deployTransparentProxy(
                "StakingRewards.sol",
                owner,
                abi.encodeCall(StakingRewards.initialize, (owner, address(cmk404Token)))
            )
        );

        // MODA Rewards
        bytes memory modaSupporterInitializerData = abi.encodeCall(
            SupporterRewards.initialize,
            (
                owner,
                address(modaToken),
                1_000 ether, // Initial burn cost
                100 ether, // Burn cost increment
                1_000 ether, // Initial stake cost
                100 ether, // Stake cost increment
                2_000 ether, // Total allocation
                address(stakingRewards),
                true // Can stake MODA
            )
        );
        SupporterRewards modaRewards = SupporterRewards(
            Upgrades.deployTransparentProxy("SupporterRewards.sol", owner, modaSupporterInitializerData)
        );

        // EMT Rewards
        bytes memory emtSupporterInitializerData = abi.encodeCall(
            SupporterRewards.initialize,
            (
                owner,
                address(modaToken),
                1_000 ether, // Initial burn cost
                100 ether, // Burn cost increment
                1_000 ether, // Initial stake cost
                100 ether, // Stake cost increment
                500 ether, // Total allocation
                address(stakingRewards),
                false // Can stake EMT
            )
        );
        SupporterRewards emtRewards = SupporterRewards(
            Upgrades.deployTransparentProxy("SupporterRewards.sol", owner, emtSupporterInitializerData)
        );

        // Grant roles for staking
        stakingRewards.grantRole(keccak256("BURNER_ROLE"), address(modaRewards));
        stakingRewards.grantRole(keccak256("BURNER_ROLE"), address(emtRewards));

        TestnetFaucet testnetFaucet = new TestnetFaucet();
        modaToken.transfer(address(testnetFaucet), 1_000_000);
        emtToken.transfer(address(testnetFaucet), 1_000_000);
        cmk404Token.transfer(address(testnetFaucet), 1_000);

        console.log("MODA Token deployed at:", address(modaToken));
        console.log("EMT Token deployed at:", address(emtToken));
        console.log("CMDK Genesis Kit deployed at:", address(cmk404Token));
        console.log("MODA SupporterRewards deployed at:", address(modaRewards));
        console.log("EMT SupporterRewards deployed at:", address(emtRewards));
        console.log("CMK404 StakingRewards deployed at:", address(stakingRewards));
        console.log("Testnet Faucet deployed at:", address(testnetFaucet));

        vm.stopBroadcast();
    }
}
