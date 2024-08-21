// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC404} from "erc404/interfaces/IERC404.sol";

contract TestnetFaucet {
    error TransferFailed();

    function getERC404Tokens(address tokenAddress, uint256 amount) external {
        bool success = IERC404(tokenAddress).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }
}
