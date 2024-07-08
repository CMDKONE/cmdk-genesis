// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {SupporterRewardsV2} from "./mocks/SupporterRewardsV2.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SupporterRewardsTest is Test {
    SupporterRewards public supporterRewards;
    ERC20Mock public supporterToken;
    address rewardsProxyAddress;
    CMDKGenesisKit public cmdkToken;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant NFT = 10 ** 18;
    address owner = address(1);
    address tokenHolder = address(2);
    address stranger = address(3);

    function setUp() public {
        vm.startPrank(owner);
        supporterToken = new ERC20Mock();
        cmdkToken = new CMDKGenesisKit();
        supporterToken.mint(tokenHolder, 5_000 ether);
        uint256 startBurnPrice = 1_000 ether;
        uint256 increaseStep = 100 ether;
        rewardsProxyAddress = Upgrades.deployTransparentProxy(
            "SupporterRewards.sol",
            owner,
            abi.encodeCall(
                SupporterRewards.initialize,
                (owner, address(supporterToken), address(cmdkToken), startBurnPrice, increaseStep)
            )
        );
        supporterRewards = SupporterRewards(rewardsProxyAddress);
        cmdkToken.setSkipNFTForAddress(address(supporterRewards), true);
        cmdkToken.transfer(address(supporterRewards), 2_000 * NFT);
        vm.stopPrank();
    }

    function test_setup() public view {
        assertEq(supporterRewards.supporterToken(), address(supporterToken));
        assertEq(supporterRewards.cmdkToken(), address(cmdkToken));
        assertEq(supporterRewards.startBurnPrice(), 1_000 ether);
        assertEq(supporterRewards.increaseStep(), 100 ether);
        assertEq(supporterRewards.claimEnabled(), false);
        assertEq(supporterRewards.amountAllocated(), 0);
    }

    function test_burn() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        supporterRewards.burn(1_000 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 4_000 ether);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 1 * NFT);
        assertEq(supporterToken.balanceOf(address(burnAddress)), 1_000 ether);
    }

    function test_setStartBurnPrice() public {
        vm.prank(owner);
        supporterRewards.setStartBurnPrice(200 ether);
        assertEq(supporterRewards.startBurnPrice(), 200 ether);
    }

    function test_setStartBurnPrice_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setStartBurnPrice(200 ether);
    }

    function test_burn_priceIncrease() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 3_300 ether);
        assertEq(supporterRewards.getBurnPrice(), 1_000 ether);
        supporterRewards.burn(1_000 ether);
        assertEq(supporterRewards.getBurnPrice(), 1_100 ether);
        supporterRewards.burn(1_100 ether);
        assertEq(supporterRewards.getBurnPrice(), 1_200 ether);
        supporterRewards.burn(600 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2_300 ether);
        assertEq(
            supporterRewards.allocation(address(tokenHolder)),
            2 * NFT + NFT / 2 // 2.5 NFT
        );
    }

    function test_setPriceIncreaseStep_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setPriceIncreaseStep(200 ether);
    }

    function test_setPriceIncreaseStep() public {
        vm.prank(owner);
        supporterRewards.setPriceIncreaseStep(1 ether);
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 2001 ether);
        supporterRewards.burn(1_000 ether);
        supporterRewards.burn(1001 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2999 ether);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 2 * NFT);
    }

    function test_claim_claimEnbled() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        supporterRewards.burn(1_000 ether);
        vm.expectRevert(SupporterRewards.ClaimingNotEnabled.selector);
        supporterRewards.claim();
        vm.stopPrank();
    }

    function test_setClaimEnabled_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setClaimEnabled(true);
    }

    function test_claim() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.startPrank(tokenHolder);
        supporterRewards.burn(1_000 ether);
        vm.startPrank(owner);
        supporterRewards.setClaimEnabled(true);
        vm.startPrank(tokenHolder);
        supporterRewards.claim();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 4_000 ether);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 0);
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 1 * NFT);
    }

    function test_claim_noDoubleClaim() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.startPrank(tokenHolder);
        supporterRewards.burn(1_000 ether);
        vm.startPrank(owner);
        supporterRewards.setClaimEnabled(true);
        vm.startPrank(tokenHolder);
        supporterRewards.claim();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 4_000 ether);
        assertEq(supporterRewards.allocation(address(tokenHolder)), 0);
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 1 * NFT);
        vm.expectRevert(SupporterRewards.MustBeNonZero.selector);
        supporterRewards.claim();
    }

    function test_withdrawCmdk() public {
        vm.startPrank(owner);
        supporterRewards.withdrawCmdk(2_000 ether);
        assertEq(cmdkToken.balanceOf(address(owner)), 5_000 ether);
        assertEq(cmdkToken.balanceOf(address(supporterRewards)), 0);
    }

    function test_upgrade() public {
        vm.startPrank(owner);
        Upgrades.upgradeProxy(
            rewardsProxyAddress,
            "SupporterRewardsV2.sol",
            abi.encodeCall(SupporterRewardsV2.initializeV2, ())
        );
        assertEq(SupporterRewardsV2(rewardsProxyAddress).version(), 2);
    }

    function test_burn_InsufficientRewards() public {
        vm.startPrank(owner);
        supporterRewards.withdrawCmdk(2_000 ether - 1);
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.expectRevert(SupporterRewards.InsufficientRewards.selector);
        supporterRewards.burn(1_000 ether);
        vm.stopPrank();
    }
}
