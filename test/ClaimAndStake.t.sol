// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClaimAndStake} from "../src/ClaimAndStake.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Merkle} from "murky/Merkle.sol";

contract ClaimAndStakeTest is Test {
    CMDKGenesisKit cmdkGenesisKit;
    ClaimAndStake claimAndStake;
    Merkle merkleTree;
    bytes32[] aliceProof;
    bytes32[] bobProof;

    address owner = address(1);
    address stranger = address(2);
    address alice = address(3);
    address bob = address(4);
    uint256 aliceAmount = 123;
    uint256 bobAmount = 456;

    error AlreadyClaimed();
    error InvalidProof();

    function setUp() public {
        cmdkGenesisKit = new CMDKGenesisKit(owner);
        claimAndStake = new ClaimAndStake(owner, address(cmdkGenesisKit));
        vm.prank(owner);
        cmdkGenesisKit.setERC721TransferExempt(address(claimAndStake), true);
        vm.prank(owner);
        cmdkGenesisKit.transfer(address(claimAndStake), 100 ether);
        // Merkle tree
        merkleTree = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(alice, aliceAmount));
        data[1] = keccak256(abi.encodePacked(bob, bobAmount));
        bytes32 root = merkleTree.getRoot(data);
        vm.prank(owner);
        claimAndStake.setMerkleRoot(root);
        aliceProof = merkleTree.getProof(data, 0);
        bobProof = merkleTree.getProof(data, 1);
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
        claimAndStake.claim(aliceAmount, aliceProof);
        uint256 amount = claimAndStake.usersStake(alice, 0).amount;
        uint256 startTime = claimAndStake.usersStake(alice, 0).startTime;
        uint256 claimTime = claimAndStake.usersStake(alice, 0).claimTime;
        assertEq(amount, aliceAmount);
        assertEq(startTime, block.timestamp);
        assertEq(claimTime, 0);
        vm.prank(bob);
        claimAndStake.claim(bobAmount, bobProof);
    }

    function test_claim_wrongProof_revert() public {
        vm.prank(alice);
        vm.expectRevert(InvalidProof.selector);
        claimAndStake.claim(aliceAmount, bobProof);
        assertEq(cmdkGenesisKit.balanceOf(alice), 0);
    }

    function test_claim_AlreadyClaimed_revert() public {
        vm.prank(alice);
        claimAndStake.claim(aliceAmount, aliceProof);
        vm.expectRevert(AlreadyClaimed.selector);
        vm.prank(alice);
        claimAndStake.claim(aliceAmount, aliceProof);
    }
}
