// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Principle Rewards
 * @notice Principle Rewards original supporters of MODA and Emanate
 * Users can stake or burn MODA in return for CMDKGenesisKit tokens.
 * Users can burn EMT in return for CMDKGenesisKit tokens.
 */
contract PrincipleRewards is OwnableUpgradeable {
    address public modaToken;
    address public emtToken;

    // External functions
    // ...

    fallback() external {
        // ...
    }
    receive() external payable {
        // ...
    }

    // Private functions
    // ...

    // Public functions
    // ...

    function initialize(
        address modaToken_,
        address emtToken_
    ) public initializer {
        modaToken = modaToken_;
        emtToken = emtToken_;
    }

    // Internal functions
    // ...

    function stakeModa(uint256 amount) public {
        // TODO: Implement
    }

    function burnModa(uint256 amount) public {
        // IERC20(modaToken).transfer(recipient, amount);
    }
}
