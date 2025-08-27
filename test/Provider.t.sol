// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/MockFlashLoanProvider.sol";
import "../src/BorrowerExample.sol";
import "../src/BadgeNFT.sol";
import "../src/IFlashBorrower.sol";

contract MockFlashLoanProviderTest is Test {
    MockERC20 public testToken;
    MockFlashLoanProvider public provider;
    BorrowerExample public borrower;
    BadgeNFT public badge;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    event FlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 fee);
    event FlashLoanSuccess(address indexed user, address indexed token, uint256 amount);

    function setUp() public {
        // Deploy contracts
        testToken = new MockERC20("Test Token", "TEST", 18, 1000000);
        provider = new MockFlashLoanProvider();
        badge = new BadgeNFT("Flash Loan Badge", "FLB", address(provider));
        borrower = new BorrowerExample();

        // Setup
        provider.setTokenWhitelist(address(testToken), true);
        
        // Add liquidity to provider
        uint256 liquidity = 100000 * 10**18;
        testToken.transfer(address(provider), liquidity);
        
        // Give borrower some funds for fees
        testToken.transfer(address(borrower), 1000 * 10**18);
    }

    function testFlashLoanSuccess() public {
        uint256 borrowAmount = 1000 * 10**18;
        uint256 expectedFee = provider.calculateFee(borrowAmount);
        
        // Check initial balances
        uint256 providerBalanceBefore = testToken.balanceOf(address(provider));
        uint256 borrowerBalanceBefore = testToken.balanceOf(address(borrower));
        
        // Execute flash loan
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
        
        // Check final balances
        uint256 providerBalanceAfter = testToken.balanceOf(address(provider));
        uint256 borrowerBalanceAfter = testToken.balanceOf(address(borrower));
        
        // Provider should have gained the fee
        assertEq(providerBalanceAfter, providerBalanceBefore + expectedFee);
        
        // Borrower should have paid the fee
        assertEq(borrowerBalanceAfter, borrowerBalanceBefore - expectedFee);
        
        // Check tracking
        assertTrue(provider.hasUserSuccessfullyBorrowed(user1));
        assertEq(provider.totalBorrowed(address(testToken)), borrowAmount);
        assertEq(provider.totalRepaid(address(testToken)), borrowAmount + expectedFee);
    }

    function testFlashLoanEvents() public {
        uint256 borrowAmount = 1000 * 10**18;
        uint256 expectedFee = provider.calculateFee(borrowAmount);
        
        // Expect events to be emitted
        vm.expectEmit(true, true, false, true);
        emit FlashLoan(address(borrower), address(testToken), borrowAmount, expectedFee);
        
        vm.expectEmit(true, true, false, true);
        emit FlashLoanSuccess(user1, address(testToken), borrowAmount);
        
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
    }

    function testFlashLoanInsufficientLiquidity() public {
        uint256 borrowAmount = 1000000 * 10**18; // More than available
        
        vm.prank(user1);
        vm.expectRevert("Insufficient liquidity");
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
    }

    function testFlashLoanUnwhitelistedToken() public {
        MockERC20 unwhitelistedToken = new MockERC20("Bad Token", "BAD", 18, 1000);
        uint256 borrowAmount = 100 * 10**18;
        
        vm.prank(user1);
        vm.expectRevert("Token not whitelisted");
        borrower.executeFlashLoan(
            address(provider),
            address(unwhitelistedToken),
            borrowAmount,
            ""
        );
    }

    function testFlashLoanZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            0,
            ""
        );
    }

    function testFeeCalculation() public {
        // Default fee is 30 bps (0.3%)
        uint256 amount = 10000 * 10**18;
        uint256 expectedFee = (amount * 30) / 10000;
        
        assertEq(provider.calculateFee(amount), expectedFee);
        
        // Change fee to 50 bps (0.5%)
        provider.setFee(50);
        uint256 newExpectedFee = (amount * 50) / 10000;
        
        assertEq(provider.calculateFee(amount), newExpectedFee);
    }

    function testSetFee() public {
        uint256 newFee = 100; // 1%
        
        provider.setFee(newFee);
        assertEq(provider.feeBasisPoints(), newFee);
        
        // Test maximum fee
        vm.expectRevert("Fee too high");
        provider.setFee(1001); // More than 10%
    }

    function testSetFeeOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.setFee(100);
    }

    function testTokenWhitelisting() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18, 1000);
        
        // Initially not whitelisted
        assertFalse(provider.whitelistedTokens(address(newToken)));
        
        // Whitelist token
        provider.setTokenWhitelist(address(newToken), true);
        assertTrue(provider.whitelistedTokens(address(newToken)));
        
        // Blacklist token
        provider.setTokenWhitelist(address(newToken), false);
        assertFalse(provider.whitelistedTokens(address(newToken)));
    }

    function testAddLiquidity() public {
        uint256 addAmount = 5000 * 10**18;
        uint256 balanceBefore = testToken.balanceOf(address(provider));
        
        // User adds liquidity
        testToken.transfer(user1, addAmount);
        vm.startPrank(user1);
        testToken.approve(address(provider), addAmount);
        provider.addLiquidity(address(testToken), addAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = testToken.balanceOf(address(provider));
        assertEq(balanceAfter, balanceBefore + addAmount);
    }

    function testRemoveLiquidity() public {
        uint256 removeAmount = 1000 * 10**18;
        uint256 balanceBefore = testToken.balanceOf(address(provider));
        uint256 ownerBalanceBefore = testToken.balanceOf(owner);
        
        provider.removeLiquidity(address(testToken), removeAmount);
        
        uint256 balanceAfter = testToken.balanceOf(address(provider));
        uint256 ownerBalanceAfter = testToken.balanceOf(owner);
        
        assertEq(balanceAfter, balanceBefore - removeAmount);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + removeAmount);
    }

    function testRemoveLiquidityOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.removeLiquidity(address(testToken), 1000 * 10**18);
    }

    function testGetAvailableLiquidity() public view {
        uint256 expectedLiquidity = testToken.balanceOf(address(provider));
        assertEq(provider.getAvailableLiquidity(address(testToken)), expectedLiquidity);
    }

    function testInvariantProviderNeverLosesMoney() public {
        uint256 initialBalance = testToken.balanceOf(address(provider));
        
        // Execute multiple flash loans
        for (uint256 i = 0; i < 5; i++) {
            uint256 borrowAmount = (i + 1) * 100 * 10**18;
            
            vm.prank(address(uint160(i + 10))); // Different users
            borrower.executeFlashLoan(
                address(provider),
                address(testToken),
                borrowAmount,
                ""
            );
        }
        
        uint256 finalBalance = testToken.balanceOf(address(provider));
        
        // Provider should have more money than before (collected fees)
        assertGt(finalBalance, initialBalance);
    }
}

// Test for malicious borrower that doesn't repay
contract MaliciousBorrower is IFlashBorrower {
    function onFlashLoan(
        address /* token */,
        uint256 /* amount */,
        uint256 /* fee */,
        bytes calldata /* data */
    ) external pure override returns (bool) {
        // Don't approve repayment - this should cause the flash loan to fail
        return true;
    }
}

contract FlashLoanSecurityTest is Test {
    MockERC20 public testToken;
    MockFlashLoanProvider public provider;
    MaliciousBorrower public maliciousBorrower;

    function setUp() public {
        testToken = new MockERC20("Test Token", "TEST", 18, 1000000);
        provider = new MockFlashLoanProvider();
        maliciousBorrower = new MaliciousBorrower();

        provider.setTokenWhitelist(address(testToken), true);
        testToken.transfer(address(provider), 100000 * 10**18);
    }

    function testMaliciousBorrowerReverts() public {
        uint256 borrowAmount = 1000 * 10**18;
        
        vm.expectRevert(); // Expect any revert due to insufficient allowance or repayment failure
        provider.flashLoan(
            address(testToken),
            borrowAmount,
            address(maliciousBorrower),
            ""
        );
    }
}
