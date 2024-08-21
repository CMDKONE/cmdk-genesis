// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC404} from "erc404/interfaces/IERC404.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract StakingRewards is IStakingRewards, Initializable, Ownable, ReentrancyGuardUpgradeable {
    address public cmk404Token;
    // Updatable after deployment
    bool private _claimEnabled;
    mapping(address => Stake[]) private _usersStakes;
    address[] private _stakers;

    // End of version 1 storage

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address owner_) Ownable(owner_) {
        _disableInitializers();
    }

    // External Functions

    function initialize(address owner, address cmk404Token_) external initializer {
        if (owner == address(0) || cmk404Token_ == address(0)) {
            revert AddressCannotBeZero();
        }
        cmk404Token = cmk404Token_;
    }

    /**
     * @dev Returns the state of claiming
     * @return If claiming is enabled
     */
    function claimEnabled() external view returns (bool) {
        return _claimEnabled;
    }

    /**
     * @dev Stake CMK404 tokens
     * @param amount The amount to stake
     */
    function stakeTokens(uint256 amount) external nonReentrant {
        bool success = IERC404(cmk404Token).erc20TransferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        createStakedEntry(msg.sender, amount);
    }

    /**
     * @dev Stake CMK404 tokens internally
     * @param amount The amount to stake
     */
    function stakeInternalTokens(address staker, uint256 amount) external {
        createStakedEntry(staker, amount);
    }

    /**
     * @dev Set whether or not claiming is enabled
     * @param claimEnabled_ Whether or not claiming is enabled
     */
    function setClaimEnabled(bool claimEnabled_) external onlyOwner {
        _claimEnabled = claimEnabled_;
    }

    /**
     * @dev Get the number of stakes for a user
     * @param user_ The address of the user to check
     * @return count The count of stakes for the user
     */
    function usersStakeCount(address user_) external view returns (uint256 count) {
        return _usersStakes[user_].length;
    }

    /**
     * @dev Get the staked data for a user
     * @param user_ The address of the user to check
     * @return stake The staked data for the user
     */
    function usersStake(address user_, uint256 index) external view returns (Stake memory stake) {
        return _usersStakes[user_][index];
    }

    /**
     * @dev Claim the CMK404 if claiming enabled
     */
    function claimAll() external nonReentrant {
        if (!_claimEnabled) revert ClaimingNotEnabled();

        uint256 count = _usersStakes[msg.sender].length;

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < count; i++) {
            if (!_usersStakes[msg.sender][i].claimed) {
                totalAmount += _usersStakes[msg.sender][i].amount;
            }
            _usersStakes[msg.sender][i].claimed = true;
        }

        if (totalAmount == 0) revert MustBeNonZero();
        bool success = IERC404(cmk404Token).transfer(msg.sender, totalAmount);
        if (!success) revert TransferFailed();
        emit TokensClaimed(totalAmount);
    }

    /**
     * @dev Returns the number of unique stakers
     * @param count The number of unique stakers
     */
    function userCount() external view returns (uint256 count) {
        return _stakers.length;
    }

    /**
     * @dev Returns the address of a staker
     * @param usersAddress The address of the user at a given index
     */
    function user(uint256 index) external view returns (address usersAddress) {
        return _stakers[index];
    }

    /**
     * @dev Withdraw CMDK tokens
     * @param amount The amount to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        emit TokensWithdrawn(amount);
        bool success = IERC404(cmk404Token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    // Internal functions

    /**
     * @dev Helper function to create a staked entry
     * @param amount The amount to stake
     */
    function createStakedEntry(address staker, uint256 amount) internal {
        if (amount == 0) revert MustBeNonZero();
        // If users first stake, add them to the stakers list
        if (_usersStakes[staker].length == 0) {
            _stakers.push(staker);
        }
        _usersStakes[staker].push(Stake(amount, block.timestamp, false));
        emit TokensStaked(amount);
    }
}
