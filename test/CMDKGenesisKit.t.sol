// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4906} from "./../src/interfaces/IERC4906.sol";
import {IERC7572} from "./../src/interfaces/IERC7572.sol";

contract CMDKGenesisKitTest is Test {
    CMDKGenesisKit public cmdkGenesisKit;
    uint256 constant totalNfts = 5_000;
    uint256 constant NFT = 10 ** 18;
    address owner = address(1);
    address stranger = address(2);
    address tokenHolder = address(3);
    address bridgeAddress = address(4);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event ContractURIUpdated();

    function setUp() public {
        cmdkGenesisKit = new CMDKGenesisKit(owner);
    }

    function test_setup() public view {
        assertEq(cmdkGenesisKit.name(), "CMDK Genesis Kit");
        assertEq(cmdkGenesisKit.symbol(), "$CMK404");
        assertEq(cmdkGenesisKit.totalSupply(), totalNfts * NFT);
        assertEq(cmdkGenesisKit.balanceOf(owner), totalNfts * NFT);
    }

    function test_setERC721TransferExempt() public {
        vm.prank(owner);
        cmdkGenesisKit.setERC721TransferExempt(tokenHolder, true);
        assertEq(cmdkGenesisKit.erc721TransferExempt(tokenHolder), true);
    }

    function test_setERC721TransferExempt_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkGenesisKit.setERC721TransferExempt(stranger, true);
    }

    function test_setBaseURI() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit BatchMetadataUpdate(1, totalNfts);
        cmdkGenesisKit.setBaseURI("theBaseURI");
        assertEq(cmdkGenesisKit.tokenURI(1), "theBaseURI");
    }

    function test_setBaseURI_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkGenesisKit.setBaseURI("theBaseURI");
    }

    function test_setSingleUri() public {
        vm.startPrank(owner);
        cmdkGenesisKit.setBaseURI("theBaseURI/");
        cmdkGenesisKit.setSingleUri(false);
        vm.stopPrank();
        assertEq(cmdkGenesisKit.tokenURI(1), "theBaseURI/1");
    }

    function test_setSingleUri_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkGenesisKit.setSingleUri(false);
    }

    function test_setContractURI() public {
        vm.prank(owner);
        vm.expectEmit();
        emit ContractURIUpdated();
        cmdkGenesisKit.setContractURI("theContractURI");
        assertEq(cmdkGenesisKit.contractURI(), "theContractURI");
    }

    function test_setBridgeAddress_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
    }

    function test_setBridgeAddress() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        assertEq(cmdkGenesisKit.bridgeAddress(), bridgeAddress);
    }

    function test_setContractURI_onlyOwner_revert() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        vm.prank(stranger);
        cmdkGenesisKit.setContractURI("theContractURI");
    }
}
