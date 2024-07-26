// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISupporterRewards} from "./interfaces/ISupporterRewards.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract SupporterRewards is
    ISupporterRewards,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public supporterToken;
    address public cmkStakingContract;
    uint256 public totalAllocation;
    // Updatable after deployment
    uint256 public initialBurnCost;
    uint256 public burnCostIncrement;
    uint256 public amountAllocated;
    uint256 public initialStakeCost;
    uint256 public stakeCostIncrement;

    mapping(address => uint256) public stakedSupporterTokenBalances;
    // End of version 1 storage

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // External Functions

    function initialize(
        address owner,
        address supporterToken_,
        uint256 initialBurnCost_,
        uint256 burnCostIncrement_,
        uint256 initialStakeCost_,
        uint256 stakeCostIncrement_,
        uint256 totalAllocation_,
        address cmkStakingContract_
    ) external initializer {
        if (supporterToken_ == address(0) || cmkStakingContract_ == address(0)) {
            revert AddressCannotBeZero();
        }
        OwnableUpgradeable.__Ownable_init(owner);
        supporterToken = supporterToken_;
        // Burn conditions
        initialBurnCost = initialBurnCost_;
        burnCostIncrement = burnCostIncrement_;
        // Stake conditions
        initialStakeCost = initialStakeCost_;
        stakeCostIncrement = stakeCostIncrement_;
        //
        totalAllocation = totalAllocation_;
        cmkStakingContract = cmkStakingContract_;
    }

    /**
     * @dev Set the start burn price cost
     * @param initialCost_ The amount the first NFT costs
     */
    function setInitialBurnCost(uint256 initialCost_) external onlyOwner {
        if (initialCost_ == 0) revert MustBeNonZero();
        initialBurnCost = initialCost_;
        emit InitialBurnCostSet(initialCost_);
    }

    /**
     * @dev Set the price increase amount
     * @param costIncrement_ The increase in price with each NFT staked
     */
    function setBurnCostIncrement(uint256 costIncrement_) external onlyOwner {
        if (costIncrement_ == 0) revert MustBeNonZero();
        burnCostIncrement = costIncrement_;
        emit BurnCostIncrementSet(costIncrement_);
    }

    function setInitialStakeCost(uint256 initialCost_) external onlyOwner {
        if (initialCost_ == 0) revert MustBeNonZero();
        initialStakeCost = initialCost_;
        emit InitialStakeCostSet(initialCost_);
    }

    /**
     * @dev Set the price increase amount
     * @param costIncrement_ The increase in price with each NFT staked
     */
    function setStakeCostIncrement(uint256 costIncrement_) external onlyOwner {
        if (costIncrement_ == 0) revert MustBeNonZero();
        stakeCostIncrement = costIncrement_;
        emit StakeCostIncrementSet(costIncrement_);
    }

    /**
     * @dev Burns supporter tokens to get CMDK tokens
     * @param amount The amount of supporter tokens to burn
     */
    function burnSupporterToken(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustBeNonZero();
        IERC20(supporterToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(supporterToken).safeTransfer(burnAddress, amount);
        uint256 cmkAmount = (amount * 10 ** 18) / getBurnCost();
        amountAllocated += cmkAmount;
        if (amountAllocated > totalAllocation) {
            revert InsufficientRewards();
        }
        IStakingRewards(cmkStakingContract).stakeInternalTokens(msg.sender, cmkAmount);
    }

    /**
     * @dev Stakes supporter tokens to get $CMDK tokens
     * @param amount The amount of supporter tokens to stake
     */
    function stakeSupporterTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustBeNonZero();
        IERC20(supporterToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 cmkAmount = (amount * 10 ** 18) / getStakeCost();
        amountAllocated += cmkAmount;
        if (amountAllocated > totalAllocation) {
            revert InsufficientRewards();
        }
        IStakingRewards(cmkStakingContract).stakeInternalTokens(msg.sender, cmkAmount);
        stakedSupporterTokenBalances[msg.sender] += amount;
    }

    function claimSupporterTokens() external nonReentrant {
        if (!IStakingRewards(cmkStakingContract).claimEnabled()) revert ClaimingNotEnabled();
        uint256 amount = stakedSupporterTokenBalances[msg.sender];
        if (amount == 0) revert MustBeNonZero();
        stakedSupporterTokenBalances[msg.sender] = 0;
        IERC20(supporterToken).safeTransfer(msg.sender, amount);
        emit SupporterTokensClaimed(msg.sender, amount);
    }

    // Public functions

    /**
     * @dev Get the burn amount needed to claim 1 $CMK404 token
     * @return The amount of supporter required
     */
    function getBurnCost() public view returns (uint256) {
        return ((amountAllocated * burnCostIncrement) / 10 ** 18) + initialBurnCost;
    }

    /**
     * @dev Get the stake amount needed to claim 1 $CMK404 token
     * @return The amount of supporter required
     */
    function getStakeCost() public view returns (uint256) {
        return ((amountAllocated * stakeCostIncrement) / 10 ** 18) + initialStakeCost;
    }

    // Internal functions
}
