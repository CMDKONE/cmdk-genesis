// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestnetFaucet {
    using SafeERC20 for IERC20;

    function getTokens(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
