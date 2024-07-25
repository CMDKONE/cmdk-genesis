// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISupporterRewards {
    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();

    event InitialBurnCostSet(uint256 initialBurnPrice_);
    event BurnCostIncrementSet(uint256 costIncrement_);
    event InitialStakeCostSet(uint256 initialStakePrice_);
    event StakeCostIncrementSet(uint256 costIncrement_);

    function initialize(
        address owner,
        address supporterToken_,
        uint256 startBurnPrice_,
        uint256 increaseStep_,
        uint256 initialStakeCost_,
        uint256 stakeCostIncrement_,
        uint256 totalAllocation_,
        address cmkStakingContract_
    ) external;

    function setInitialBurnCost(uint256 startBurnPrice_) external;

    function setBurnCostIncrement(uint256 increaseStep_) external;

    function burnSupporterToken(uint256 amount) external;

    function stakeSupporterToken(uint256 amount) external;

    function getBurnCost() external view returns (uint256);

    function getStakeCost() external view returns (uint256);
}
