// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract StakingRewards is IStakingRewards, Initializable, AccessControlUpgradeable {
    bytes32 public constant SUPPORTER_ROLE = keccak256("SUPPORTER_ROLE");

    address public cmdkToken;
    // Updatable after deployment
    bool public claimEnabled;
    mapping(address => Stake[]) usersStakes;
    address[] private _stakers;

    // End of version 1 storage

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // External Functions

    function initialize(address owner, address cmdkToken_) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        cmdkToken = cmdkToken_;
    }

    /**
     * @dev Stake CMDK tokens
     * @param amount The amount to stake
     */
    function stakeTokens(uint256 amount) external {
        IERC20(cmdkToken).transferFrom(msg.sender, address(this), amount);
        createStakedEntry(msg.sender, amount);
    }

    /**
     * @dev Stake CMDK tokens internally
     * @param amount The amount to stake
     */
    function stakeInternalTokens(address staker, uint256 amount) external onlyRole(SUPPORTER_ROLE) {
        createStakedEntry(staker, amount);
    }

    /**
     * @dev Set whether or not claiming is enabled
     * @param claimEnabled_ Whether or not claiming is enabled
     */
    function setClaimEnabled(bool claimEnabled_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnabled = claimEnabled_;
    }

    /**
     * @dev Get the number of stakes for a user
     * @param user The address of the user to check
     * @return count The count of stakes for the user
     */
    function usersStakeCount(address user) external view returns (uint256 count) {
        return usersStakes[user].length;
    }

    /**
     * @dev Get the staked data for a user
     * @param user The address of the user to check
     * @return stake The staked data for the user
     */
    function usersStake(address user, uint256 stakeIndex) external view returns (Stake memory stake) {
        return usersStakes[user][stakeIndex];
    }

    /**
     * @dev Claim the CMDK if claiming enabled
     */
    function claimAll() external {
        if (!claimEnabled) revert ClaimingNotEnabled();

        uint256 count = usersStakes[msg.sender].length;

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < count; i++) {
            if (!usersStakes[msg.sender][i].claimed) {
                totalAmount += usersStakes[msg.sender][i].amount;
            }
            usersStakes[msg.sender][i].claimed = true;
        }

        if (totalAmount == 0) revert MustBeNonZero();
        IERC20(cmdkToken).transfer(msg.sender, totalAmount);
        emit TokensClaimed(totalAmount);
    }

    // Internal functions

    /**
     * @dev Helper function to create a staked entry
     * @param amount The amount to stake
     */
    function createStakedEntry(address staker, uint256 amount) internal {
        if (amount == 0) revert MustBeNonZero();
        // If users first stake, add them to the stakers list
        if (usersStakes[staker].length == 0) {
            _stakers.push(staker);
        }
        usersStakes[staker].push(Stake(amount, block.timestamp, false));
        emit TokensStaked(amount);
    }
}
