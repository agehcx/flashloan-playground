// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFlashBorrower.sol";

/**
 * @title BorrowerExample
 * @dev Example flash loan borrower that demonstrates a simple profitable strategy
 */
contract BorrowerExample is IFlashBorrower, Ownable {
    // Events
    event FlashLoanReceived(address token, uint256 amount, uint256 fee);
    event MockProfitGenerated(uint256 profit);
    event FlashLoanCompleted(bool success);

    // State for tracking operations
    mapping(address => uint256) public totalFlashLoansReceived;
    mapping(address => uint256) public totalProfitGenerated;
    
    // Mock profit rate (in basis points) - simulates arbitrage profit
    uint256 public mockProfitBasisPoints = 50; // 0.5% profit simulation

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Handle the flash loan callback
     * @param token The address of the token borrowed
     * @param amount The amount borrowed
     * @param fee The fee to be paid
     * @return success Whether the operation was successful
     */
    function onFlashLoan(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata /* data */
    ) external override returns (bool success) {
        emit FlashLoanReceived(token, amount, fee);
        
        // Track the flash loan
        totalFlashLoansReceived[token] += amount;

        // Simulate some profitable operation (like arbitrage)
        bool profitGenerated = _simulateProfitableOperation(token, amount);
        
        if (profitGenerated) {
            // Calculate simulated profit
            uint256 profit = (amount * mockProfitBasisPoints) / 10000;
            totalProfitGenerated[token] += profit;
            emit MockProfitGenerated(profit);
        }

        // Calculate total repayment needed
        uint256 totalRepayment = amount + fee;
        
        // Ensure we have enough balance to repay (including any profit generated)
        IERC20 tokenContract = IERC20(token);
        uint256 currentBalance = tokenContract.balanceOf(address(this));
        
        require(currentBalance >= totalRepayment, "Insufficient balance to repay");

        // Approve the flash loan provider to take the repayment
        require(
            tokenContract.approve(msg.sender, totalRepayment),
            "Approval failed"
        );

        emit FlashLoanCompleted(true);
        return true;
    }

    /**
     * @dev Simulate a profitable operation (like arbitrage or yield farming)
     * @param amount The amount being operated on
     * @return Whether profit was generated
     */
    function _simulateProfitableOperation(address /* token */, uint256 amount) internal view returns (bool) {
        // In a real scenario, this would be:
        // 1. Swap tokens on DEX A
        // 2. Swap back on DEX B at better rate
        // 3. Capture price difference as profit
        // 4. Or: Use funds for liquidation and capture liquidation bonus
        // 5. Or: Deposit in yield farm, harvest rewards, withdraw
        
        // For demo purposes, we'll mint some tokens to simulate profit
        // In practice, the strategy would need to generate real profit
        
        uint256 simulatedProfit = (amount * mockProfitBasisPoints) / 10000;
        
        // Simulate receiving profit tokens (in real scenario, this would come from DEX/protocol)
        // For demo, we'll assume the profit is automatically credited
        // This is just for demonstration - real strategies must generate actual profit!
        
        return simulatedProfit > 0;
    }

    /**
     * @dev Execute a flash loan from a provider
     * @param provider The flash loan provider address
     * @param token The token to borrow
     * @param amount The amount to borrow
     * @param data Additional data to pass
     */
    function executeFlashLoan(
        address provider,
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        // Call the flash loan provider
        (bool success, ) = provider.call(
            abi.encodeWithSignature(
                "flashLoan(address,uint256,address,bytes)",
                token,
                amount,
                address(this),
                data
            )
        );
        require(success, "Flash loan execution failed");
    }

    /**
     * @dev Set the mock profit rate (owner only)
     * @param newProfitBasisPoints New profit rate in basis points
     */
    function setMockProfitRate(uint256 newProfitBasisPoints) external onlyOwner {
        require(newProfitBasisPoints <= 1000, "Profit rate too high"); // Max 10%
        mockProfitBasisPoints = newProfitBasisPoints;
    }

    /**
     * @dev Withdraw any leftover tokens (owner only)
     * @param token The token to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner(), amount), "Transfer failed");
    }

    /**
     * @dev Add some tokens to this contract for operations
     * @param token The token to add
     * @param amount The amount to add
     */
    function addOperatingFunds(address token, uint256 amount) external {
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    /**
     * @dev Get current balance of a token
     * @param token The token address
     * @return The current balance
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Get total profits generated for a token
     * @param token The token address
     * @return The total profit generated
     */
    function getTotalProfit(address token) external view returns (uint256) {
        return totalProfitGenerated[token];
    }
}
