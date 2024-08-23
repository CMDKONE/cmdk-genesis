// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC404} from "erc404/interfaces/IERC404.sol";
import {IClaimAndStake} from "./interfaces/IClaimAndStake.sol";

contract ClaimAndStake is IClaimAndStake, Ownable, ReentrancyGuard {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    address private immutable cmk404Address;
    mapping(address => Stake[]) private _usersStakes;
    address[] private _stakers;
    bool public unstakeEnabled = false;

    constructor(address owner, address cmk404Address_) Ownable(owner) {
        if (cmk404Address_ == address(0)) revert AddressCannotBeZero();
        cmk404Address = cmk404Address_;
    }

    // External functions

    /**
     * @dev Set the merkle root for the whitelist
     * @param merkleRoot_ The merkle root for the whitelist
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Enable or disable unstaking
     * @param enabled Whether or not unstaking is enabled
     */
    function setUnstakeEnabled(bool enabled) external onlyOwner {
        unstakeEnabled = enabled;
    }

    /**
     * @dev Claim CMK404 tokens
     * @param amount The amount for the claim
     * @param merkleProof The proof for the claim
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();
        claimed[msg.sender] = true;
        createStakedEntry(msg.sender, amount, 2);
    }

    /**
     * @dev Stake CMK404 tokens
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external nonReentrant {
        bool success = IERC404(cmk404Address).erc20TransferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        createStakedEntry(msg.sender, amount, 1);
    }

    /**
     * @dev Unstake all users tokens
     */
    function unstakeAll() external {
        if (!unstakeEnabled) revert UnstakingNotEnabled();

        uint256 count = _usersStakes[msg.sender].length;

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < count; i++) {
            // If the stake is not claimed
            if (_usersStakes[msg.sender][i].claimTime == 0) {
                totalAmount += _usersStakes[msg.sender][i].amount;
                _usersStakes[msg.sender][i].claimTime = block.timestamp;
            }
        }

        if (totalAmount == 0) revert MustBeNonZero();
        bool success = IERC404(cmk404Address).transfer(msg.sender, totalAmount);
        if (!success) revert TransferFailed();
        emit TokensClaimed(totalAmount);
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
     * @return stakedEntry The staked data for the user
     */
    function usersStake(address user_, uint256 index) external view returns (Stake memory stakedEntry) {
        return _usersStakes[user_][index];
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
    function ownerWithdrawTokens(uint256 amount) external onlyOwner {
        emit TokensWithdrawn(amount);
        bool success = IERC404(cmk404Address).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    // Private functions
    // Public functions
    // Internal functions

    /**
     * @dev Helper function to create a staked entry
     * @param amount The amount to stake
     */
    function createStakedEntry(address staker, uint256 amount, uint16 multiplier) internal {
        if (amount == 0) revert MustBeNonZero();
        // If this is the users first stake, add them to the stakers list
        if (_usersStakes[staker].length == 0) {
            _stakers.push(staker);
        }
        _usersStakes[staker].push(Stake(amount, block.timestamp, 0, multiplier));
        emit TokensStaked(amount);
    }
}
