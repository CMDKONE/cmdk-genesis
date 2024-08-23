// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CMDKLaunchKit} from "../src/CMDKLaunchKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4906} from "./../src/interfaces/IERC4906.sol";
import {IERC7572} from "./../src/interfaces/IERC7572.sol";

contract CMDKLaunchKitTest is Test {
    CMDKLaunchKit public cmdkLaunchKit;
    uint256 constant totalNfts = 5_000;
    uint256 constant NFT = 10 ** 18;
    address owner = address(1);
    address stranger = address(2);
    address tokenHolder = address(3);
    address bridgeAddress = address(4);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event ContractURIUpdated();

    function setUp() public {
        cmdkLaunchKit = new CMDKLaunchKit(owner, "theName", "theSymbol");
    }

    function test_setup() public view {
        assertEq(cmdkLaunchKit.name(), "theName");
        assertEq(cmdkLaunchKit.symbol(), "theSymbol");
        assertEq(cmdkLaunchKit.totalSupply(), totalNfts * NFT);
        assertEq(cmdkLaunchKit.balanceOf(owner), totalNfts * NFT);
    }

    function test_setERC721TransferExempt() public {
        vm.prank(owner);
        cmdkLaunchKit.setERC721TransferExempt(tokenHolder, true);
        assertEq(cmdkLaunchKit.erc721TransferExempt(tokenHolder), true);
    }

    function test_setERC721TransferExempt_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkLaunchKit.setERC721TransferExempt(stranger, true);
    }

    function test_setBaseURI() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(1, totalNfts);
        cmdkLaunchKit.setBaseURI("theBaseURI");
        assertEq(cmdkLaunchKit.tokenURI(1), "theBaseURI");
    }

    function test_setBaseURI_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkLaunchKit.setBaseURI("theBaseURI");
    }

    function test_setSingleUri() public {
        vm.startPrank(owner);
        cmdkLaunchKit.setBaseURI("theBaseURI/");
        cmdkLaunchKit.setSingleUri(false);
        vm.stopPrank();
        assertEq(cmdkLaunchKit.tokenURI(1), "theBaseURI/1");
    }

    function test_setSingleUri_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkLaunchKit.setSingleUri(false);
    }

    function test_setContractURI() public {
        vm.prank(owner);
        vm.expectEmit();
        emit ContractURIUpdated();
        cmdkLaunchKit.setContractURI("theContractURI");
        assertEq(cmdkLaunchKit.contractURI(), "theContractURI");
    }

    function test_setBridgeAddress_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkLaunchKit.setBridgeAddress(bridgeAddress);
    }

    function test_setBridgeAddress() public {
        vm.prank(owner);
        cmdkLaunchKit.setBridgeAddress(bridgeAddress);
        assertEq(cmdkLaunchKit.bridgeAddress(), bridgeAddress);
    }

    function test_setContractURI_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkLaunchKit.setContractURI("theContractURI");
    }
}
