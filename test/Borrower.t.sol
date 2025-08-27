// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/MockFlashLoanProvider.sol";
import "../src/BorrowerExample.sol";

contract BorrowerExampleTest is Test {
    MockERC20 public testToken;
    MockFlashLoanProvider public provider;
    BorrowerExample public borrower;
    
    address public owner = address(this);
    address public user1 = address(0x1);

    function setUp() public {
        // Deploy contracts
        testToken = new MockERC20("Test Token", "TEST", 18, 1000000);
        provider = new MockFlashLoanProvider();
        borrower = new BorrowerExample();

        // Setup
        provider.setTokenWhitelist(address(testToken), true);
        
        // Add liquidity to provider
        uint256 liquidity = 100000 * 10**18;
        testToken.transfer(address(provider), liquidity);
        
        // Give borrower some funds for fees and operations
        testToken.transfer(address(borrower), 10000 * 10**18);
    }

    function testSuccessfulFlashLoan() public {
        uint256 borrowAmount = 1000 * 10**18;
        uint256 borrowerBalanceBefore = testToken.balanceOf(address(borrower));
        
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
        
        uint256 borrowerBalanceAfter = testToken.balanceOf(address(borrower));
        
        // Borrower should have paid the fee
        uint256 expectedFee = provider.calculateFee(borrowAmount);
        assertEq(borrowerBalanceAfter, borrowerBalanceBefore - expectedFee);
        
        // Check tracking
        assertEq(borrower.totalFlashLoansReceived(address(testToken)), borrowAmount);
        assertGt(borrower.totalProfitGenerated(address(testToken)), 0);
    }

    function testOnFlashLoanCallback() public {
        uint256 borrowAmount = 1000 * 10**18;
        uint256 fee = provider.calculateFee(borrowAmount);
        
        // Simulate the provider calling the callback
        vm.prank(address(provider));
        bool success = borrower.onFlashLoan(
            address(testToken),
            borrowAmount,
            fee,
            ""
        );
        
        assertTrue(success);
        assertEq(borrower.totalFlashLoansReceived(address(testToken)), borrowAmount);
    }

    function testSetMockProfitRate() public {
        uint256 newRate = 100; // 1%
        
        borrower.setMockProfitRate(newRate);
        assertEq(borrower.mockProfitBasisPoints(), newRate);
        
        // Test maximum rate
        vm.expectRevert("Profit rate too high");
        borrower.setMockProfitRate(1001); // More than 10%
    }

    function testSetMockProfitRateOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        borrower.setMockProfitRate(100);
    }

    function testAddOperatingFunds() public {
        uint256 addAmount = 1000 * 10**18;
        uint256 balanceBefore = testToken.balanceOf(address(borrower));
        
        testToken.transfer(user1, addAmount);
        vm.startPrank(user1);
        testToken.approve(address(borrower), addAmount);
        borrower.addOperatingFunds(address(testToken), addAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = testToken.balanceOf(address(borrower));
        assertEq(balanceAfter, balanceBefore + addAmount);
    }

    function testWithdrawToken() public {
        uint256 withdrawAmount = 1000 * 10**18;
        uint256 borrowerBalanceBefore = testToken.balanceOf(address(borrower));
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        
        borrower.withdrawToken(address(testToken), withdrawAmount);
        
        uint256 borrowerBalanceAfter = testToken.balanceOf(address(borrower));
        uint256 ownerBalanceAfter = testToken.balanceOf(owner);
        
        assertEq(borrowerBalanceAfter, borrowerBalanceBefore - withdrawAmount);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + withdrawAmount);
    }

    function testWithdrawTokenOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        borrower.withdrawToken(address(testToken), 1000 * 10**18);
    }

    function testGetTokenBalance() public view {
        uint256 expectedBalance = testToken.balanceOf(address(borrower));
        assertEq(borrower.getTokenBalance(address(testToken)), expectedBalance);
    }

    function testGetTotalProfit() public {
        // Initially no profit
        assertEq(borrower.getTotalProfit(address(testToken)), 0);
        
        // Execute flash loan to generate profit
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            1000 * 10**18,
            ""
        );
        
        // Should have generated some profit
        assertGt(borrower.getTotalProfit(address(testToken)), 0);
    }

    function testInsufficientBalanceForRepayment() public {
        // Create borrower with insufficient funds
        BorrowerExample poorBorrower = new BorrowerExample();
        
        // Give it very little funds (not enough for fee)
        testToken.transfer(address(poorBorrower), 1 * 10**18);
        
        uint256 borrowAmount = 1000 * 10**18;
        
        vm.expectRevert(); // Expect any revert due to insufficient balance
        poorBorrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
    }

    function testExecuteFlashLoanAnyUser() public {
        uint256 borrowAmount = 500 * 10**18;
        
        // Any user should be able to execute flash loan
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
        
        // Check that it worked
        assertEq(borrower.totalFlashLoansReceived(address(testToken)), borrowAmount);
    }
}
