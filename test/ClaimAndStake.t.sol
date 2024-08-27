// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClaimAndStake} from "../src/ClaimAndStake.sol";
import {CMDKLaunchKit} from "../src/CMDKLaunchKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Merkle} from "murky/Merkle.sol";

contract ClaimAndStakeTest is Test {
    CMDKLaunchKit cmdkLaunchKit;
    ClaimAndStake claimAndStake;
    Merkle merkleTree;
    bytes32[] aliceProof;
    bytes32[] bobProof;

    address owner = address(1);
    address stranger = address(2);
    address alice = address(3);
    address bob = address(4);
    uint256 aliceAllocationAmount = 123;
    uint256 bobAllocationAmount = 456;

    error AlreadyClaimed();
    error InvalidProof();

    function setUp() public {
        cmdkLaunchKit = new CMDKLaunchKit(owner, "name", "symbol");
        claimAndStake = new ClaimAndStake(owner, address(cmdkLaunchKit));
        vm.startPrank(owner);
        cmdkLaunchKit.setERC721TransferExempt(address(claimAndStake), true);
        cmdkLaunchKit.transfer(address(claimAndStake), 100 ether);
        cmdkLaunchKit.transfer(address(alice), 100 ether);
        cmdkLaunchKit.transfer(address(bob), 100 ether);
        // Merkle tree
        merkleTree = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(alice, aliceAllocationAmount));
        data[1] = keccak256(abi.encodePacked(bob, bobAllocationAmount));
        bytes32 root = merkleTree.getRoot(data);
        claimAndStake.setMerkleRoot(root);
        aliceProof = merkleTree.getProof(data, 0);
        bobProof = merkleTree.getProof(data, 1);
        vm.stopPrank();
    }

    function test_setMerkleRoot_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        claimAndStake.setMerkleRoot("theMerkleRoot");
    }

    function test_setMerkleRoot() public {
        vm.prank(owner);
        claimAndStake.setMerkleRoot("theMerkleRoot");
        assertEq(claimAndStake.merkleRoot(), "theMerkleRoot");
    }

    function test_claim() public {
        vm.prank(alice);
        claimAndStake.claim(aliceAllocationAmount, aliceProof);
        vm.prank(bob);
        claimAndStake.claim(bobAllocationAmount, bobProof);
        assertEq(claimAndStake.userCount(), 2);
        assertEq(claimAndStake.usersStake(alice, 0).amount, aliceAllocationAmount);
        assertEq(claimAndStake.usersStake(alice, 0).startTime, block.timestamp);
        assertEq(claimAndStake.usersStake(alice, 0).claimTime, 0);
        assertEq(claimAndStake.usersStake(bob, 0).amount, bobAllocationAmount);
        assertEq(claimAndStake.usersStake(bob, 0).startTime, block.timestamp);
        assertEq(claimAndStake.usersStake(bob, 0).claimTime, 0);
    }

    function test_claim_wrongProof_revert() public {
        uint256 startBalance = cmdkLaunchKit.balanceOf(alice);
        vm.prank(alice);
        vm.expectRevert(InvalidProof.selector);
        claimAndStake.claim(aliceAllocationAmount, bobProof);
        assertEq(cmdkLaunchKit.balanceOf(alice), startBalance);
    }

    function test_claim_AlreadyClaimed_revert() public {
        vm.prank(alice);
        claimAndStake.claim(aliceAllocationAmount, aliceProof);
        vm.expectRevert(AlreadyClaimed.selector);
        vm.prank(alice);
        claimAndStake.claim(aliceAllocationAmount, aliceProof);
    }

    function test_stake() public {
        vm.prank(alice);
        cmdkLaunchKit.approve(address(claimAndStake), aliceAllocationAmount);
        vm.prank(alice);
        claimAndStake.stake(aliceAllocationAmount);
        assertEq(claimAndStake.usersStake(alice, 0).amount, aliceAllocationAmount);
        assertEq(claimAndStake.usersStake(alice, 0).startTime, block.timestamp);
        assertEq(claimAndStake.usersStake(alice, 0).claimTime, 0);
    }

    function test_unstake() public {
        vm.prank(owner);
        claimAndStake.setUnstakeEnabled(true);
        vm.startPrank(alice);
        uint256 startBalance = cmdkLaunchKit.balanceOf(alice);
        cmdkLaunchKit.approve(address(claimAndStake), 3 ether);
        // Stake 1
        uint256 startTime1 = block.timestamp;
        claimAndStake.stake(1 ether);
        // Stake 2
        uint256 startTime2 = block.timestamp + 10 seconds;
        vm.warp(startTime2);
        claimAndStake.stake(2 ether);
        // Unstake All
        uint256 endTime = block.timestamp + 10 seconds;
        vm.warp(endTime);
        claimAndStake.unstakeAll();
        assertEq(cmdkLaunchKit.balanceOf(alice), startBalance);
        // Check stakes
        assertEq(claimAndStake.usersStake(alice, 0).amount, 1 ether);
        assertEq(claimAndStake.usersStake(alice, 0).startTime, startTime1);
        assertEq(claimAndStake.usersStake(alice, 0).claimTime, endTime);
        assertEq(claimAndStake.usersStake(alice, 1).amount, 2 ether);
        assertEq(claimAndStake.usersStake(alice, 1).startTime, startTime2);
        assertEq(claimAndStake.usersStake(alice, 1).claimTime, endTime);
    }
}
