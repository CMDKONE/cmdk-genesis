// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC404} from "erc404/interfaces/IERC404.sol";

contract WhitelistClaim is Ownable {
    error TransferFailed();
    error InvalidProof();
    error AlreadyClaimed();

    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    address public immutable tokenAddress;

    constructor(address owner, address tokenAddress_) Ownable(owner) {
        tokenAddress = tokenAddress_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function claim(uint256 quantity, bytes32[] calldata merkleProof) public {
        if (claimed[msg.sender]) revert AlreadyClaimed();
        bytes32 node = keccak256(abi.encodePacked(msg.sender, quantity));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();
        claimed[msg.sender] = true;
        bool success = IERC404(tokenAddress).transfer(msg.sender, quantity);
        if (!success) revert TransferFailed();
    }
}
