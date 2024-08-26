// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC404} from "erc404/interfaces/IERC404.sol";

contract Faucet {
    address private immutable cmk404Address;

    constructor(address cmk404Address_) {
        cmk404Address = cmk404Address_;
    }

    function getTokens() external {
        bool success = IERC404(cmk404Address).transfer(msg.sender, 1);
        if (!success) revert("Transfer failed");
    }
}
