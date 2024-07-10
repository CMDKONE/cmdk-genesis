// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingRewards} from "../../src/StakingRewards.sol";

/// @custom:oz-upgrades-from StakingRewards
contract StakingRewardsV2 is StakingRewards {
    uint256 public version;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2() public reinitializer(2) {
        version = 2;
    }
}
