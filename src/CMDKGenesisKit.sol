// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "dn404/src/DN404.sol";
import "dn404/src/DN404Mirror.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/**
 * @title CMDK Genesis Kit
 * @notice CMDK Genesis Kit begins with fungible tokens.
 * When a user has at least one base unit (10^18) amount of tokens, they will automatically receive an NFT.
 * NFTs are minted as an address accumulates each base unit amount of tokens.
 */
contract CMDKGenesisKit is DN404, Ownable {
    string private _baseURI;

    constructor() {
        _initializeOwner(msg.sender);
        uint96 initialTokenSupply = (10_000) * 10 ** 18;
        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, msg.sender, mirror);
    }

    function name() public pure override returns (string memory) {
        return "CMDK Genesis Kit";
    }

    function symbol() public pure override returns (string memory) {
        return "$CMK404";
    }

    function _tokenURI(
        uint256 tokenId
    ) internal view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(
                abi.encodePacked(_baseURI, LibString.toString(tokenId))
            );
        }
    }

    // This allows the owner of the contract to mint more tokens.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }
}
