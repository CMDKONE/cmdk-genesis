// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

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

    uint256 constant NFT = 10 ** 18;

    function setUp() public {
        vm.startPrank(owner);
        supporterToken = new ERC20Mock();
        cmdkToken = new CMDKGenesisKit();
        supporterToken.mint(tokenHolder, 5000);
        address beacon = Upgrades.deployBeacon(
            "SupporterRewards.sol:SupporterRewards",
            owner
        );
        uint256 startBurnPrice = 1000;
        uint256 increaseStep = 100;
        supporterRewards = SupporterRewards(
            Upgrades.deployBeaconProxy(
                beacon,
                abi.encodeCall(
                    SupporterRewards.initialize,
                    (
                        owner,
                        address(supporterToken),
                        address(cmdkToken),
                        startBurnPrice,
                        increaseStep
                    )
                )
            )
        );
        cmdkToken.setSkipNFTForAddress(address(supporterRewards), true);
        cmdkToken.transfer(address(supporterRewards), 2_000 * NFT);
        vm.stopPrank();
    }

    function test_burn() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1000);
        supporterRewards.burn(1000);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 4000);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 1 * NFT);
    }

    function test_burn_priceIncrease() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 3300);
        assertEq(supporterRewards.getBurnPrice(), 1000);
        supporterRewards.burn(1000);
        assertEq(supporterRewards.getBurnPrice(), 1100);
        supporterRewards.burn(1100);
        assertEq(supporterRewards.getBurnPrice(), 1200);
        supporterRewards.burn(600);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2300);
        assertEq(
            supporterRewards.allocation(address(tokenHolder)),
            2 * NFT + NFT / 2 // 2.5 NFT
        );
    }

    function test_setReturnPercentage_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                stranger
            )
        );
        supporterRewards.setPriceIncreaseStep(200);
    }

    function test_setPriceIncreaseStep() public {
        vm.prank(owner);
        supporterRewards.setPriceIncreaseStep(1);
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 2001);
        supporterRewards.burn(1000);
        supporterRewards.burn(1001);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2999);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 2 * NFT);
    }

    function test_claim_claimEnbled() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1000);
        supporterRewards.burn(1000);
        vm.expectRevert(SupporterRewards.ClaimingNotEnabled.selector);
        supporterRewards.claim();
        vm.stopPrank();
    }

    function test_setClaimEnabled_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                stranger
            )
        );
        supporterRewards.setClaimEnabled(true);
    }

    function test_claim() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1000);
        vm.startPrank(tokenHolder);
        supporterRewards.burn(1000);
        vm.startPrank(owner);
        supporterRewards.setClaimEnabled(true);
        vm.startPrank(tokenHolder);
        supporterRewards.claim();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 4000);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 0);
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 1 * NFT);
    }

    function test_withdraw() public {
        vm.startPrank(owner);
        supporterRewards.withdraw(2_000 * 10 ** 18);
        assertEq(cmdkToken.balanceOf(address(owner)), 5_000 * 10 ** 18);
    }
}
