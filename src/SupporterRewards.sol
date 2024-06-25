// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";

/**
 * @title Supporter Rewards
 * @notice Supporter Rewards original supporters of MODA and Emanate
 * Users can stake or burn supporterToken in return for CMDKGenesisKit tokens.
 * @dev This contract is upgradeable.
 */
contract SupporterRewards is Initializable, OwnableUpgradeable {
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address public supporterToken;
    address public cmdkToken;
    // Updatable after deployment
    uint256 public percentageDecimal;
    uint256 public burnReturnPercent;
    // End of version 1 storage

    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();

    function setReturnPercentage(uint256 percentage) external onlyOwner {
        if (percentage == 0) revert MustBeNonZero();
        burnReturnPercent = percentage;
    }

    function burn(uint256 amount) external {
        if (amount == 0) revert MustBeNonZero();
        IERC20(supporterToken).transferFrom(msg.sender, address(this), amount);
        uint256 payout = (amount * burnReturnPercent) / percentageDecimal;
        if (payout > IERC20(cmdkToken).balanceOf(address(this)))
            revert InsufficientRewards();
        IERC20(cmdkToken).transfer(msg.sender, payout);
    }

    // Private functions
    // ...

    // Public functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address supporterToken_,
        address cmdkToken_
    ) public initializer {
        if (supporterToken_ == address(0) || cmdkToken_ == address(0)) {
            revert AddressCannotBeZero();
        }
        OwnableUpgradeable.__Ownable_init(owner);
        supporterToken = supporterToken_;
        cmdkToken = cmdkToken_;
        percentageDecimal = 100_000; // 100%
        burnReturnPercent = 50_000; // 50% - 100 for every 200 burned
    }

    // Internal functions
    // ...
}
