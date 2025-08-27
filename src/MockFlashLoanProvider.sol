// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IFlashBorrower.sol";

/**
 * @title MockFlashLoanProvider
 * @dev A simple flash loan provider for testing and demonstrations
 */
contract MockFlashLoanProvider is Ownable, ReentrancyGuard {
    // Events
    event FlashLoan(
        address indexed borrower,
        address indexed token,
        uint256 amount,
        uint256 fee
    );
    
    event FlashLoanSuccess(address indexed user, address indexed token, uint256 amount);
    
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    
    event TokenWhitelisted(address indexed token, bool whitelisted);

    // State variables
    uint256 public feeBasisPoints = 30; // 0.3% default fee
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public totalBorrowed;
    mapping(address => uint256) public totalRepaid;
    mapping(address => bool) public hasSuccessfullyBorrowed;

    // Constants
    uint256 public constant MAX_FEE_BPS = 1000; // 10% max fee

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Execute a flash loan
     * @param token The address of the token to borrow
     * @param amount The amount to borrow
     * @param receiver The address that will receive the tokens and handle the callback
     * @param data Additional data to pass to the receiver
     */
    function flashLoan(
        address token,
        uint256 amount,
        address receiver,
        bytes calldata data
    ) external nonReentrant {
        require(whitelistedTokens[token], "Token not whitelisted");
        require(amount > 0, "Amount must be greater than 0");
        require(receiver != address(0), "Invalid receiver");

        IERC20 tokenContract = IERC20(token);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");

        // Calculate fee
        uint256 fee = (amount * feeBasisPoints) / 10000;
        uint256 totalAmount = amount + fee;

        // Track borrowing
        totalBorrowed[token] += amount;

        // Transfer tokens to receiver
        require(tokenContract.transfer(receiver, amount), "Transfer failed");

        // Call the receiver
        require(
            IFlashBorrower(receiver).onFlashLoan(token, amount, fee, data),
            "Flash loan callback failed"
        );

        // Collect repayment from receiver
        require(
            tokenContract.transferFrom(receiver, address(this), totalAmount),
            "Flash loan repayment failed"
        );

        // Verify final balance
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore + fee,
            "Flash loan not repaid correctly"
        );

        // Track successful repayment
        totalRepaid[token] += totalAmount;
        
        // Mark user as having successfully borrowed (for NFT badge)
        // Use tx.origin to track the actual user who initiated the transaction
        address actualUser = tx.origin;
        if (!hasSuccessfullyBorrowed[actualUser]) {
            hasSuccessfullyBorrowed[actualUser] = true;
        }

        emit FlashLoan(receiver, token, amount, fee);
        emit FlashLoanSuccess(actualUser, token, amount);
    }

    /**
     * @dev Add liquidity to the provider
     * @param token The token to add
     * @param amount The amount to add
     */
    function addLiquidity(address token, uint256 amount) external {
        require(whitelistedTokens[token], "Token not whitelisted");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Remove liquidity from the provider (owner only)
     * @param token The token to remove
     * @param amount The amount to remove
     */
    function removeLiquidity(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transfer(owner(), amount), "Transfer failed");
    }

    /**
     * @dev Set the fee rate (owner only)
     * @param newFeeBasisPoints New fee in basis points (100 = 1%)
     */
    function setFee(uint256 newFeeBasisPoints) external onlyOwner {
        require(newFeeBasisPoints <= MAX_FEE_BPS, "Fee too high");
        
        uint256 oldFee = feeBasisPoints;
        feeBasisPoints = newFeeBasisPoints;
        
        emit FeeUpdated(oldFee, newFeeBasisPoints);
    }

    /**
     * @dev Whitelist or blacklist a token (owner only)
     * @param token The token address
     * @param whitelisted Whether the token should be whitelisted
     */
    function setTokenWhitelist(address token, bool whitelisted) external onlyOwner {
        whitelistedTokens[token] = whitelisted;
        emit TokenWhitelisted(token, whitelisted);
    }

    /**
     * @dev Get the current fee for a given amount
     * @param amount The amount to calculate fee for
     * @return The fee amount
     */
    function calculateFee(uint256 amount) external view returns (uint256) {
        return (amount * feeBasisPoints) / 10000;
    }

    /**
     * @dev Get available liquidity for a token
     * @param token The token address
     * @return The available balance
     */
    function getAvailableLiquidity(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Check if user has successfully completed a flash loan
     * @param user The user address
     * @return Whether the user has successfully borrowed
     */
    function hasUserSuccessfullyBorrowed(address user) external view returns (bool) {
        return hasSuccessfullyBorrowed[user];
    }
}