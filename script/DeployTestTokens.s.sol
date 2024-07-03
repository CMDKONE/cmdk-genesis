// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
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
        vm.startBroadcast(privateKey);

        // Deploy MODAToken
        SupporterToken modaToken = new SupporterToken("MODA", "MODA");
        // Deploy EMTToken
        SupporterToken emtToken = new SupporterToken("EMT", "EMT");

        console.log("MODAToken deployed at:", address(modaToken));
        console.log("EMTToken deployed at:", address(emtToken));

        vm.stopBroadcast();
    }
}
