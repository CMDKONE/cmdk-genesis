// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title Principle Rewards
 * @notice Principle Rewards original supporters of MODA and Emanate
 * Users can stake or burn MODA in return for CMDKGenesisKit tokens.
 * Users can burn EMT in return for CMDKGenesisKit tokens.
 */
contract PrincipleRewards {
    IERC20 private modaToken = IERC20(0x0);
    IERC20 private emtToken = IERC20(0x0);

    function stakeModa(uint256 amount) public {
        // TODO: Implement
    }

    function burnModa(uint256 amount) public {
        // modaToken.transfer(recipient, amount);
    }
}
