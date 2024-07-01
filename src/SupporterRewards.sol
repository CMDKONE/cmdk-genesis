// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";

/**
 * @title Supporter Rewards
 * @notice Supporter Rewards original supporters of MODA and Emanate
 * Users can stake or burn supporterToken in return for CMDKGenesisKit tokens.
 * @dev This contract is upgradeable.
 */
contract SupporterRewards is Initializable, OwnableUpgradeable {
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

    error MustBeNonZero();
    error InsufficientRewards();
    error AddressCannotBeZero();
    error ClaimingNotEnabled();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // External Functions

    /**
     * @dev Initialize the contract
     * @param owner The owner of the contract
     * @param supporterToken_ The token to stake
     * @param cmdkToken_ The token to receive
     * @param startBurnPrice_ The initial price to burn
     * @param increaseStep_ The price increase per NFT allocated
     */
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
     * @dev Set burn price increase rate
     * @param increaseStep_ The amount to increase by
     */
    function setPriceIncreaseStep(uint256 increaseStep_) external onlyOwner {
        if (increaseStep_ == 0) revert MustBeNonZero();
        increaseStep = increaseStep_;
    }

    /**
     * @dev Set claiming open or closed
     * @param claimEnabled_ The new claim state
     */
    function setClaimEnabled(bool claimEnabled_) external onlyOwner {
        claimEnabled = claimEnabled_;
    }

    /**
     * @dev Burn supporterToken to receive CMDKGenesisKit tokens
     * @param amount The amount of supporterToken to burn
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
    }

    /**
     * @dev Get the allocation for a user
     * @param user The address of the user to check
     * @return The allocation for the user
     */
    function allocation(address user) external view returns (uint256) {
        return pendingRewards[user];
    }

    function claim() external {
        if (!claimEnabled) revert ClaimingNotEnabled();
        uint256 amount = pendingRewards[msg.sender];
        if (amount == 0) revert MustBeNonZero();
        pendingRewards[msg.sender] = 0;
        IERC20(cmdkToken).transfer(msg.sender, amount);
    }

    /**
     * @dev Owner function to withdraw left over CMDK tokens from the contract
     * @param amount The amount of CMDK to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        IERC20(cmdkToken).transfer(owner(), amount);
    }

    // Private functions

    // Public functions

    /**
     * @dev Get the current burn price
     * @return The current burn price
     */
    function getBurnPrice() public view returns (uint256) {
        return ((amountAllocated * increaseStep) / 10 ** 18) + startBurnPrice;
    }

    // Internal functions
}
