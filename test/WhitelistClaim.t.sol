// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WhitelistClaim} from "../src/WhitelistClaim.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistClaimTest is Test {
    CMDKGenesisKit public cmdkGenesisKit;
    WhitelistClaim public whitelistClaim;

    address owner = address(1);
    address stranger = address(2);
    address alice = address(3);
    address bob = address(4);

    function setUp() public {
        cmdkGenesisKit = new CMDKGenesisKit(owner);
        whitelistClaim = new WhitelistClaim(owner, address(cmdkGenesisKit));
    }

    function test_setup() public view {}

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
        //
    }
}
