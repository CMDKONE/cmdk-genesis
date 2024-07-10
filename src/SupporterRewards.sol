// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISupporterRewards} from "./interfaces/ISupporterRewards.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract SupporterRewards is ISupporterRewards, Initializable, OwnableUpgradeable {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public supporterToken;
    address public stakingContract;
    uint256 public totalAllocation;
    // Updatable after deployment
    uint256 public startBurnPrice;
    uint256 public increaseStep;
    bool public claimEnabled;
    uint256 public amountAllocated;
    // End of version 1 storage

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // External Functions

    function initialize(
        address owner,
        address supporterToken_,
        uint256 startBurnPrice_,
        uint256 increaseStep_,
        uint256 totalAllocation_,
        address stakingContract_
    ) external initializer {
        if (supporterToken_ == address(0)) {
            revert AddressCannotBeZero();
        }
        OwnableUpgradeable.__Ownable_init(owner);
        supporterToken = supporterToken_;
        startBurnPrice = startBurnPrice_; // Number of token to burn to get 1 NFT
        increaseStep = increaseStep_; // Price increase per NFT allocated
        totalAllocation = totalAllocation_; // Total rewards to allocate
        stakingContract = stakingContract_;
    }

    /**
     * @dev Set the start burn price cost
     * @param startBurnPrice_ The amount the first NFT costs
     */
    function setStartBurnPrice(uint256 startBurnPrice_) external onlyOwner {
        if (startBurnPrice_ == 0) revert MustBeNonZero();
        startBurnPrice = startBurnPrice_;
    }

    /**
     * @dev Set the price increase amount
     * @param increaseStep_ The amount each nft sold increases price
     */
    function setPriceIncreaseStep(uint256 increaseStep_) external onlyOwner {
        if (increaseStep_ == 0) revert MustBeNonZero();
        increaseStep = increaseStep_;
    }

    /**
     * @dev Burns supporter tokens to get CMDK tokens
     * @param amount The amount of supporter tokens to burn
     */
    function burn(uint256 amount) external {
        if (amount == 0) revert MustBeNonZero();
        IERC20(supporterToken).transferFrom(msg.sender, address(this), amount);
        IERC20(supporterToken).transfer(burnAddress, amount);
        uint256 payout = (amount * 10 ** 18) / getBurnPrice();
        amountAllocated += payout;
        if (amountAllocated > totalAllocation) {
            revert InsufficientRewards();
        }
        IStakingRewards(stakingContract).stakeInternalTokens(msg.sender, payout);
    }

    /**
     * @dev Get the price to claim 1 CMDK token
     * @return The price
     */
    function getBurnPrice() public view returns (uint256) {
        return ((amountAllocated * increaseStep) / 10 ** 18) + startBurnPrice;
    }

    // Internal functions
}
