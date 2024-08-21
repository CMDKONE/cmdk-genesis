// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WhitelistClaim} from "../src/WhitelistClaim.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Merkle} from "murky/Merkle.sol";

contract WhitelistClaimTest is Test {
    CMDKGenesisKit cmdkGenesisKit;
    WhitelistClaim whitelistClaim;
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

    function setUp() public {
        cmdkGenesisKit = new CMDKGenesisKit(owner);
        whitelistClaim = new WhitelistClaim(owner, address(cmdkGenesisKit));
        vm.prank(owner);
        cmdkGenesisKit.setERC721TransferExempt(address(whitelistClaim), true);
        vm.prank(owner);
        cmdkGenesisKit.transfer(address(whitelistClaim), 100 ether);
        // Merkle tree
        merkleTree = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(alice, aliceAmount));
        data[1] = keccak256(abi.encodePacked(bob, bobAmount));
        bytes32 root = merkleTree.getRoot(data);
        vm.prank(owner);
        whitelistClaim.setMerkleRoot(root);
        aliceProof = merkleTree.getProof(data, 0);
        bobProof = merkleTree.getProof(data, 0);
    }

    function test_setMerkleRoot_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        whitelistClaim.setMerkleRoot("theMerkleRoot");
    }

    function test_setMerkleRoot() public {
        vm.prank(owner);
        whitelistClaim.setMerkleRoot("theMerkleRoot");
        assertEq(whitelistClaim.merkleRoot(), "theMerkleRoot");
    }

    function test_claim() public {
        vm.prank(alice);
        whitelistClaim.claim(aliceAmount, aliceProof);
        assertEq(cmdkGenesisKit.balanceOf(alice), aliceAmount);
    }

    function test_claim_claimTwice_revert() public {
        vm.prank(alice);
        whitelistClaim.claim(aliceAmount, aliceProof);
        vm.expectRevert(AlreadyClaimed.selector);
        vm.prank(alice);
        whitelistClaim.claim(aliceAmount, aliceProof);
        assertEq(cmdkGenesisKit.balanceOf(alice), aliceAmount);
    }
}
