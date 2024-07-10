// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISupporterRewards {
    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();

    function initialize(
        address owner,
        address supporterToken_,
        uint256 startBurnPrice_,
        uint256 increaseStep_,
        uint256 totalAllocation_,
        address stakingContract_
    ) external;

    function setStartBurnPrice(uint256 startBurnPrice_) external;

    function setPriceIncreaseStep(uint256 increaseStep_) external;

    function burn(uint256 amount) external;

    function getBurnPrice() external view returns (uint256);
}
