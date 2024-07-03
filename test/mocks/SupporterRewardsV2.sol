// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SupporterRewards} from "../../src/SupporterRewards.sol";

/// @custom:oz-upgrades-from SupporterRewards
contract SupporterRewardsV2 is SupporterRewards {
    uint256 public version;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2() public reinitializer(2) {
        version = 2;
    }
}
