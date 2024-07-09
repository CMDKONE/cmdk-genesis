// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISupporterRewards} from "./interfaces/ISupporterRewards.sol";

contract SupporterRewards is ISupporterRewards, Initializable, OwnableUpgradeable {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public supporterToken;
    address public cmdkToken;
    // Updatable after deployment
    uint256 public startBurnPrice;
    uint256 public increaseStep;
    bool public claimEnabled;
    mapping(address => uint256) pendingRewards;
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
        address cmdkToken_,
        uint256 startBurnPrice_,
        uint256 increaseStep_
    ) external initializer {
        if (supporterToken_ == address(0) || cmdkToken_ == address(0)) {
            revert AddressCannotBeZero();
        }
        OwnableUpgradeable.__Ownable_init(owner);
        supporterToken = supporterToken_;
        cmdkToken = cmdkToken_;
        startBurnPrice = startBurnPrice_; // Number of token to burn to get 1 NFT
        increaseStep = increaseStep_; // Price increase per NFT allocated
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
     * @dev Set whether or not claiming is enabled
     * @param claimEnabled_ Whether or not claiming is enabled
     */
    function setClaimEnabled(bool claimEnabled_) external onlyOwner {
        claimEnabled = claimEnabled_;
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
        if (amountAllocated > IERC20(cmdkToken).balanceOf(address(this))) {
            revert InsufficientRewards();
        }
        pendingRewards[msg.sender] += payout;

        emit TokensAllocated(payout);
    }

    /**
     * @dev Get the allocation for a user
     * @param user The address of the user to check
     * @return The allocation for the user
     */
    function allocation(address user) external view returns (uint256) {
        return pendingRewards[user];
    }

    /**
     * @dev Claim the CMDK if claiming enabled
     */
    function claim() external {
        if (!claimEnabled) revert ClaimingNotEnabled();
        uint256 amount = pendingRewards[msg.sender];
        if (amount == 0) revert MustBeNonZero();
        pendingRewards[msg.sender] = 0;
        IERC20(cmdkToken).transfer(msg.sender, amount);
    }

    /**
     * @dev Lets owner withdraw CMDK tokens
     * @param amount The amount of CMDK tokens to withdraw
     */
    function withdrawCmdk(uint256 amount) external onlyOwner {
        IERC20(cmdkToken).transfer(owner(), amount);
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
