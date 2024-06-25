// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SupporterRewardsTest is Test {
    SupporterRewards public supporterRewards;
    ERC20Mock public supporterToken;
    CMDKGenesisKit public cmdkToken;
    address owner = address(1);
    address tokenHolder = address(2);
    address stranger = address(1000);

    function setUp() public {
        vm.prank(owner);
        supporterToken = new ERC20Mock();
        cmdkToken = new CMDKGenesisKit();
        supporterToken.mint(owner, 1000);

        address beacon = Upgrades.deployBeacon(
            "SupporterRewards.sol:SupporterRewards",
            owner
        );
        supporterRewards = SupporterRewards(
            Upgrades.deployBeaconProxy(
                beacon,
                abi.encodeCall(
                    SupporterRewards.initialize,
                    (owner, address(supporterToken), address(cmdkToken))
                )
            )
        );

        cmdkToken.transfer(address(supporterRewards), 1_000_000);
    }

    function test_burn() public {
        vm.prank(owner);
        supporterToken.approve(address(supporterRewards), 100);
        vm.prank(owner);
        supporterRewards.burn(100);
        assertEq(supporterToken.balanceOf(address(owner)), 900);
        assertEq(cmdkToken.balanceOf(address(owner)), 50);
    }

    function test_setReturnPercentage_onlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                stranger
            )
        );
        vm.prank(stranger);
        supporterRewards.setReturnPercentage(10);
    }

    // function test_setReturnPercentage() public {
    //     vm.prank(owner);
    //     supporterRewards.setReturnPercentage(1000);
    //     vm.prank(owner);
    //     supporterToken.approve(address(supporterRewards), 100);
    //     vm.prank(owner);
    //     supporterRewards.burn(100);
    //     assertEq(supporterToken.balanceOf(address(owner)), 900);
    //     assertEq(cmdkToken.balanceOf(address(owner)), 10);
    // }
}
