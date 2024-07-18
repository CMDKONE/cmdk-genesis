// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract StakingRewards is
    IStakingRewards,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

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
        if (owner == address(0) || cmdkToken_ == address(0)) {
            revert AddressCannotBeZero();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        cmdkToken = cmdkToken_;
    }

    /**
     * @dev Stake CMDK tokens
     * @param amount The amount to stake
     */
    function stakeTokens(uint256 amount) external nonReentrant {
        IERC20(cmdkToken).safeTransferFrom(msg.sender, address(this), amount);
        createStakedEntry(msg.sender, amount);
    }

    /**
     * @dev Stake CMDK tokens internally
     * @param amount The amount to stake
     */
    function stakeInternalTokens(address staker, uint256 amount) external onlyRole(BURNER_ROLE) {
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
     * @param user_ The address of the user to check
     * @return count The count of stakes for the user
     */
    function usersStakeCount(address user_) external view returns (uint256 count) {
        return usersStakes[user_].length;
    }

    /**
     * @dev Get the staked data for a user
     * @param user_ The address of the user to check
     * @return stake The staked data for the user
     */
    function usersStake(address user_, uint256 index) external view returns (Stake memory stake) {
        return usersStakes[user_][index];
    }

    /**
     * @dev Claim the CMDK if claiming enabled
     */
    function claimAll() external nonReentrant {
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
        IERC20(cmdkToken).safeTransfer(msg.sender, totalAmount);
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
