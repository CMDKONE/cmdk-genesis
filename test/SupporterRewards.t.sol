// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ISupporterRewards} from "../src/interfaces/ISupporterRewards.sol";
import {IStakingRewards} from "../src/interfaces/IStakingRewards.sol";
import {SupporterRewards} from "../src/SupporterRewards.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {SupporterRewardsV2} from "./mocks/SupporterRewardsV2.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SupporterRewardsTest is Test {
    StakingRewards public stakingRewards;
    SupporterRewards public supporterRewards;
    ERC20Mock public supporterToken;
    CMDKGenesisKit public cmdkToken;
    address rewardsProxyAddress;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant NFT = 10 ** 18;
    bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address owner = address(1);
    address tokenHolder = address(2);
    address stranger = address(3);

    function helper_deployStakingRewards(address cmdkTokenAddress) internal returns (StakingRewards) {
        address stakingProxy = Upgrades.deployTransparentProxy(
            "StakingRewards.sol",
            owner,
            abi.encodeCall(StakingRewards.initialize, (owner, cmdkTokenAddress))
        );
        return StakingRewards(stakingProxy);
    }

    function helper_deploySupporterRewards(
        address supporterTokenAddress,
        address stakingRewardsAddress
    ) internal returns (SupporterRewards) {
        uint256 initialBurnCost = 1_000 ether;
        uint256 burnCostIncrement = 100 ether;
        uint256 initialStakeCost = 1_000 ether;
        uint256 stakeCostIncrement = 100 ether;
        uint256 totalAllocation = 4 * NFT;

        bytes memory initializerData = abi.encodeCall(
            SupporterRewards.initialize,
            (
                owner,
                supporterTokenAddress,
                initialBurnCost,
                burnCostIncrement,
                initialStakeCost,
                stakeCostIncrement,
                totalAllocation,
                stakingRewardsAddress
            )
        );
        rewardsProxyAddress =
            Upgrades.deployTransparentProxy("SupporterRewards.sol", owner, initializerData);
        return SupporterRewards(rewardsProxyAddress);
    }

    function setUp() public {
        vm.startPrank(owner);
        supporterToken = new ERC20Mock();
        supporterToken.mint(tokenHolder, 5_000 ether);
        cmdkToken = new CMDKGenesisKit(owner);
        stakingRewards = helper_deployStakingRewards(address(cmdkToken));
        supporterRewards =
            helper_deploySupporterRewards(address(supporterToken), address(stakingRewards));
        stakingRewards.grantRole(BURNER_ROLE, address(supporterRewards));
        cmdkToken.setERC721TransferExempt(address(stakingRewards), true);
        cmdkToken.transfer(address(stakingRewards), 2_000 * NFT);
        vm.stopPrank();
    }

    function test_setup() public view {
        assertEq(supporterRewards.supporterToken(), address(supporterToken));
        assertEq(supporterRewards.initialBurnCost(), 1_000 ether);
        assertEq(supporterRewards.burnCostIncrement(), 100 ether);
        assertEq(supporterRewards.amountAllocated(), 0);
    }

    function test_burnSupporterToken() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.expectEmit();
        emit IStakingRewards.TokensStaked(1 * NFT);
        supporterRewards.burnSupporterToken(1_000 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(tokenHolder), 4_000 ether);
        IStakingRewards.Stake memory stake = stakingRewards.usersStake(tokenHolder, 0);
        assertEq(stake.amount, 1 * NFT);
        assertEq(supporterToken.balanceOf(burnAddress), 1_000 ether);
    }

    function test_stakeSupporterToken() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.expectEmit();
        emit IStakingRewards.TokensStaked(1 * NFT);
        supporterRewards.stakeSupporterTokens(1_000 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(tokenHolder), 4_000 ether);
        IStakingRewards.Stake memory stake = stakingRewards.usersStake(tokenHolder, 0);
        assertEq(stake.amount, 1 * NFT);
        assertEq(supporterToken.balanceOf(address(supporterRewards)), 1_000 ether);
    }

    function test_setInitialBurnCost() public {
        vm.prank(owner);
        vm.expectEmit();
        emit ISupporterRewards.InitialBurnCostSet(200 ether);
        supporterRewards.setInitialBurnCost(200 ether);
        assertEq(supporterRewards.initialBurnCost(), 200 ether);
    }

    function test_setInitialBurnCost_onlyOwner_revert() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setInitialBurnCost(200 ether);
    }

    function test_setInitialStakeCost() public {
        vm.prank(owner);
        vm.expectEmit();
        emit ISupporterRewards.InitialStakeCostSet(200 ether);
        supporterRewards.setInitialStakeCost(200 ether);
        assertEq(supporterRewards.initialStakeCost(), 200 ether);
    }

    function test_setInitialStakeCost_onlyOwner_revert() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setInitialStakeCost(200 ether);
    }

    function helper_getTotalCmk404Staked(address user) internal view returns (uint256) {
        uint256 count = stakingRewards.usersStakeCount(user);
        uint256 amountStaked = 0;
        for (uint256 i = 0; i < count; i++) {
            amountStaked += stakingRewards.usersStake(tokenHolder, i).amount;
        }
        return amountStaked;
    }

    function test_burnSupporterToken_priceIncrease() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 3_300 ether);
        assertEq(supporterRewards.getBurnCost(), 1_000 ether);
        supporterRewards.burnSupporterToken(1_000 ether);
        assertEq(supporterRewards.getBurnCost(), 1_100 ether);
        supporterRewards.burnSupporterToken(1_100 ether);
        assertEq(supporterRewards.getBurnCost(), 1_200 ether);
        supporterRewards.burnSupporterToken(600 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2_300 ether);
        uint256 amountStaked = helper_getTotalCmk404Staked(tokenHolder);
        assertEq(
            amountStaked,
            2 * NFT + NFT / 2 // 2.5 NFT
        );
    }

    function test_stakeSupporterToken_priceIncrease() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 3_300 ether);
        assertEq(supporterRewards.getStakeCost(), 1_000 ether);
        supporterRewards.stakeSupporterTokens(1_000 ether);
        assertEq(supporterRewards.getStakeCost(), 1_100 ether);
        supporterRewards.stakeSupporterTokens(1_100 ether);
        assertEq(supporterRewards.getStakeCost(), 1_200 ether);
        supporterRewards.stakeSupporterTokens(600 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2_300 ether);
        uint256 amountStaked = helper_getTotalCmk404Staked(tokenHolder);
        assertEq(
            amountStaked,
            2 * NFT + NFT / 2 // 2.5 NFT
        );
    }

    function test_setPriceIncreaseStep_onlyOwner_revert() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        supporterRewards.setBurnCostIncrement(200 ether);
    }

    function test_setPriceIncreaseStep() public {
        vm.prank(owner);
        vm.expectEmit();
        emit ISupporterRewards.BurnCostIncrementSet(1 ether);
        supporterRewards.setBurnCostIncrement(1 ether);
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 2001 ether);
        supporterRewards.burnSupporterToken(1_000 ether);
        supporterRewards.burnSupporterToken(1001 ether);
        vm.stopPrank();
        assertEq(supporterToken.balanceOf(address(tokenHolder)), 2999 ether);
        uint256 amountStaked = helper_getTotalCmk404Staked(tokenHolder);
        assertEq(amountStaked, 2 * NFT);
    }

    function test_claimSupporterTokens() public {
        vm.prank(owner);
        stakingRewards.setClaimEnabled(true);
        uint256 balanceBefore = supporterToken.balanceOf(tokenHolder);
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        supporterRewards.stakeSupporterTokens(1_000 ether);
        supporterRewards.claimSupporterTokens();
        vm.stopPrank();
        uint256 balanceAfter = supporterToken.balanceOf(tokenHolder);
        assertEq(balanceAfter, balanceBefore);
    }

    function test_upgrade() public {
        vm.startPrank(owner);
        Upgrades.upgradeProxy(
            rewardsProxyAddress,
            "SupporterRewardsV2.sol",
            abi.encodeCall(SupporterRewardsV2.initializeV2, ())
        );
        assertEq(SupporterRewardsV2(rewardsProxyAddress).version(), 2);
        assertEq(SupporterRewardsV2(rewardsProxyAddress).supporterToken(), address(supporterToken));
    }

    function test_burnSupporterToken_InsufficientRewards() public {
        vm.startPrank(tokenHolder);
        supporterToken.approve(address(supporterRewards), 4_000 ether);
        supporterRewards.burnSupporterToken(4_000 ether);
        supporterToken.approve(address(supporterRewards), 1_000 ether);
        vm.expectRevert(ISupporterRewards.InsufficientRewards.selector);
        supporterRewards.burnSupporterToken(1_000 ether);
        vm.stopPrank();
    }
}
