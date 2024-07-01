// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {IERC7572} from "../src/interfaces/IERC7572.sol";

contract CMDKGenesisKitTest is Test {
    CMDKGenesisKit public cmdkGenesisKit;
    uint256 constant NFT = 10 ** 18;
    address owner = address(1);
    address stranger = address(2);
    address bridgeAddress = address(3);
    address tokenHolder = address(4);

    function setUp() public {
        vm.prank(owner);
        cmdkGenesisKit = new CMDKGenesisKit();
    }

    function test_name() public view {
        assertEq(cmdkGenesisKit.name(), "CMDK Genesis Kit");
    }

    function test_symbol() public view {
        assertEq(cmdkGenesisKit.symbol(), "$CMK404");
    }

    function test_totalSupply() public view {
        assertEq(cmdkGenesisKit.totalSupply(), (5_000) * NFT);
    }

    function test_balanceOf() public view {
        assertEq(cmdkGenesisKit.balanceOf(owner), (5_000) * NFT);
    }

    function test_setSkipNFTForAddress() public {
        vm.prank(owner);
        cmdkGenesisKit.setSkipNFTForAddress(tokenHolder, true);
        assertEq(cmdkGenesisKit.getSkipNFT(tokenHolder), true);
    }

    function test_setSkipNFTForAddress_onlyOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(stranger);
        cmdkGenesisKit.setSkipNFTForAddress(stranger, true);
    }

    function test_setContractURI() public {
        vm.prank(owner);
        vm.expectEmit();
        emit IERC7572.ContractURIUpdated();
        cmdkGenesisKit.setContractURI("theContractURI");
        assertEq(cmdkGenesisKit.contractURI(), "theContractURI");
    }

    function test_setContractURI_onlyOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(stranger);
        cmdkGenesisKit.setContractURI("theContractURI");
    }

    function test_setBridgeAddress() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        assertEq(cmdkGenesisKit.bridgeAddress(), bridgeAddress);
    }

    function test_setBridgeAddress_onlyOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(stranger);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
    }

    function test_mint() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        vm.prank(bridgeAddress);
        cmdkGenesisKit.mint(tokenHolder, 1 * NFT);
        assertEq(cmdkGenesisKit.balanceOf(tokenHolder), 1 * NFT);
    }

    function test_mint_onlyBridge() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        vm.expectRevert();
        cmdkGenesisKit.mint(tokenHolder, 1 * NFT);
    }

    function test_burn() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        vm.prank(bridgeAddress);
        cmdkGenesisKit.burn(owner, 1000 * NFT);
        assertEq(cmdkGenesisKit.balanceOf(owner), 4000 * NFT);
    }

    function test_burn_onlyBridge() public {
        vm.prank(owner);
        cmdkGenesisKit.setBridgeAddress(bridgeAddress);
        vm.expectRevert();
        cmdkGenesisKit.burn(tokenHolder, 1000);
    }
}
