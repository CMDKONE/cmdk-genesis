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
import {StakingRewardsV2} from "./mocks/StakingRewardsV2.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract StakingRewardsTest is Test {
    StakingRewards public stakingRewards;
    SupporterRewards public supporterRewards;
    ERC20Mock public supporterToken;
    CMDKGenesisKit public cmdkToken;
    address rewardsProxyAddress;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant NFT = 10 ** 18;
    bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    address owner = address(1);
    address tokenHolder = address(2);
    address anotherTokenHolder = address(3);
    address stranger = address(4);

    function helper_deployStakingRewards(address cmdkTokenAddress) internal returns (StakingRewards) {
        rewardsProxyAddress = Upgrades.deployTransparentProxy(
            "StakingRewards.sol",
            owner,
            abi.encodeCall(StakingRewards.initialize, (owner, cmdkTokenAddress))
        );
        return StakingRewards(rewardsProxyAddress);
    }

    function helper_deploySupporterRewards(
        address supporterTokenAddress,
        address stakingRewardsAddress
    ) internal returns (SupporterRewards) {
        uint256 startBurnPrice = 1_000 ether;
        uint256 increaseStep = 100 ether;
        uint256 totalAllocation = 4 * NFT;
        address rewardsProxy = Upgrades.deployTransparentProxy(
            "SupporterRewards.sol",
            owner,
            abi.encodeCall(
                SupporterRewards.initialize,
                (
                    owner,
                    supporterTokenAddress,
                    startBurnPrice,
                    increaseStep,
                    totalAllocation,
                    stakingRewardsAddress
                )
            )
        );
        return SupporterRewards(rewardsProxy);
    }

    function setUp() public {
        vm.startPrank(owner);
        supporterToken = new ERC20Mock();
        supporterToken.mint(tokenHolder, 5_000 ether);
        supporterToken.mint(anotherTokenHolder, 5_000 ether);
        cmdkToken = new CMDKGenesisKit(owner);
        cmdkToken.transfer(tokenHolder, 10 * NFT);
        cmdkToken.transfer(anotherTokenHolder, 10 * NFT);
        stakingRewards = helper_deployStakingRewards(address(cmdkToken));
        supporterRewards =
            helper_deploySupporterRewards(address(supporterToken), address(stakingRewards));
<<<<<<< Updated upstream
        stakingRewards.grantRole(SUPPORTER_ROLE, address(supporterRewards));
<<<<<<< Updated upstream
        cmdkToken.setERC721TransferExempt(address(stakingRewards), true);
=======
        cmdkToken.setSkipNFTForAddress(address(stakingRewards), true);
=======
        stakingRewards.grantRole(BURNER_ROLE, address(supporterRewards));
        cmdkToken.setERC721TransferExempt(address(stakingRewards), true);
>>>>>>> Stashed changes
>>>>>>> Stashed changes
        cmdkToken.transfer(address(stakingRewards), 2_000 * NFT);
        vm.stopPrank();
    }

    function test_setup() public view {
        assertEq(stakingRewards.cmdkToken(), address(cmdkToken));
        assertEq(stakingRewards.claimEnabled(), false);
    }

    function test_stake() public {
        vm.startPrank(tokenHolder);
        cmdkToken.approve(address(stakingRewards), 1 * NFT);
        vm.expectEmit();
        emit IStakingRewards.TokensStaked(1 * NFT);
        stakingRewards.stakeTokens(1 * NFT);
        vm.stopPrank();
        assertEq(cmdkToken.balanceOf(tokenHolder), 9 * NFT);
        IStakingRewards.Stake memory stake = stakingRewards.usersStake(tokenHolder, 0);
        assertEq(stake.amount, 1 * NFT);
    }

    function test_userCount() public {
        vm.startPrank(tokenHolder);
        cmdkToken.approve(address(stakingRewards), 1 * NFT);
        stakingRewards.stakeTokens(1 * NFT);
        vm.stopPrank();
        uint256 numUsers = stakingRewards.userCount();
        assertEq(numUsers, 1);
        address firstUser = stakingRewards.user(0);
        assertEq(firstUser, tokenHolder);
        vm.startPrank(anotherTokenHolder);
        cmdkToken.approve(address(stakingRewards), 1 * NFT);
        stakingRewards.stakeTokens(1 * NFT);
        vm.stopPrank();
        numUsers = stakingRewards.userCount();
        assertEq(numUsers, 2);
        address secondUser = stakingRewards.user(1);
        assertEq(secondUser, anotherTokenHolder);
    }

    function test_stakeInternal_onlyRole() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, stranger, BURNER_ROLE
            )
        );
        stakingRewards.stakeInternalTokens(stranger, 1 * NFT);
    }

    function test_claimAll_claimEnbled() public {
        vm.startPrank(tokenHolder);
        cmdkToken.approve(address(stakingRewards), 10 * NFT);
        stakingRewards.stakeTokens(10 * NFT);
        vm.expectRevert(IStakingRewards.ClaimingNotEnabled.selector);
        stakingRewards.claimAll();
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 0);
        vm.stopPrank();
    }

    function test_setClaimEnabled_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, stranger, DEFAULT_ADMIN_ROLE
            )
        );
        stakingRewards.setClaimEnabled(true);
    }

    function test_claimAll() public {
        vm.prank(owner);
        stakingRewards.setClaimEnabled(true);
        vm.startPrank(tokenHolder);
        cmdkToken.approve(address(stakingRewards), 10 * NFT);
        stakingRewards.stakeTokens(10 * NFT);
        stakingRewards.claimAll();
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 10 * NFT);
        vm.stopPrank();
    }

    function test_claim_noDoubleClaim() public {
        vm.prank(owner);
        stakingRewards.setClaimEnabled(true);
        vm.startPrank(tokenHolder);
        cmdkToken.approve(address(stakingRewards), 10 * NFT);
        stakingRewards.stakeTokens(10 * NFT);
        stakingRewards.claimAll();
        vm.expectRevert(IStakingRewards.MustBeNonZero.selector);
        stakingRewards.claimAll();
        assertEq(cmdkToken.balanceOf(address(tokenHolder)), 10 * NFT);
        vm.stopPrank();
    }

    function test_upgrade() public {
        vm.startPrank(owner);
        Upgrades.upgradeProxy(
            rewardsProxyAddress,
            "StakingRewardsV2.sol",
            abi.encodeCall(StakingRewardsV2.initializeV2, ())
        );
        assertEq(StakingRewardsV2(rewardsProxyAddress).version(), 2);
        assertEq(StakingRewardsV2(rewardsProxyAddress).cmdkToken(), address(cmdkToken));
    }
}
