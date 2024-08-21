// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingRewards {
    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();
    error ClaimingNotEnabled();
    error Unauthorized();
    error TransferFailed();

    event TokensStaked(uint256 amount);
    event TokensClaimed(uint256 amount);
    event TokensWithdrawn(uint256 amount);

    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    function initialize(address owner, address cmdkToken_) external;

    function claimEnabled() external view returns (bool);

    function stakeTokens(uint256 amount) external;

    function stakeInternalTokens(address staker, uint256 amount) external;

    function setClaimEnabled(bool claimEnabled_) external;

    function usersStakeCount(address user_) external view returns (uint256 count);

    function usersStake(address user_, uint256 count) external view returns (Stake memory stake);

    function userCount() external view returns (uint256 count);

    function user(uint256 index) external view returns (address usersAddress);

    function withdrawTokens(uint256 amount) external;

    function claimAll() external;
}
