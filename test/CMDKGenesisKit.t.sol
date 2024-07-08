// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {CMDKGenesisKit} from "../src/CMDKGenesisKit.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {IERC7572} from "../src/interfaces/IERC7572.sol";
import {IERC4906} from "../src/interfaces/IERC4906.sol";

contract CMDKGenesisKitTest is Test {
    CMDKGenesisKit public cmdkGenesisKit;
    uint256 constant totalNfts = 5_000;
    uint256 constant NFT = 10 ** 18;
    address owner = address(1);
    address stranger = address(2);
    address tokenHolder = address(3);

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

    function test_totalNfts() public view {
        assertEq(cmdkGenesisKit.totalSupply(), totalNfts * NFT);
    }

    function test_balanceOf() public view {
        assertEq(cmdkGenesisKit.balanceOf(owner), totalNfts * NFT);
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

    function test_setBaseURI() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit IERC4906.BatchMetadataUpdate(1, totalNfts);
        cmdkGenesisKit.setBaseURI("theBaseURI");
        assertEq(cmdkGenesisKit.tokenURI(1), "theBaseURI");
    }

    function test_setBaseURI_onlyOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
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
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(stranger);
        cmdkGenesisKit.setSingleUri(false);
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
}
