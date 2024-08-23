// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IClaimAndStake {
    error InvalidProof();
    error AlreadyClaimed();
    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();
    error UnstakingNotEnabled();
    error Unauthorized();
    error TransferFailed();

    event TokensStaked(uint256 amount);
    event TokensClaimed(uint256 amount);
    event TokensWithdrawn(uint256 amount);

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 claimTime;
        uint16 multiplier;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external;

    function setUnstakeEnabled(bool enabled) external;

    function claim(uint256 amount, bytes32[] calldata merkleProof) external;

    function stake(uint256 amount) external;

    function unstakeAll() external;

    function usersStakeCount(address user_) external view returns (uint256 count);

    function usersStake(address user_, uint256 index) external view returns (Stake memory stakedEntry);

    function userCount() external view returns (uint256 count);

    function user(uint256 index) external view returns (address usersAddress);

    function ownerWithdrawTokens(uint256 amount) external;
}
