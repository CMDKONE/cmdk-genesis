// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISupporterRewards {
    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();
    error ClaimingNotEnabled();

    event TokensAllocated(uint256 amount);

    // External Functions

    function initialize(
        address owner,
        address supporterToken_,
        address cmdkToken_,
        uint256 startBurnPrice_,
        uint256 increaseStep_
    ) external;

    function setStartBurnPrice(uint256 startBurnPrice_) external;

    function setPriceIncreaseStep(uint256 increaseStep_) external;

    function setClaimEnabled(bool claimEnabled_) external;

    function burn(uint256 amount) external;

    function allocation(address user) external view returns (uint256);

    function claim() external;

    function withdrawCmdk(uint256 amount) external;

    function getBurnPrice() external view returns (uint256);
}
