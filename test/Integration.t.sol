// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/MockFlashLoanProvider.sol";
import "../src/BorrowerExample.sol";
import "../src/BadgeNFT.sol";

contract IntegrationTest is Test {
    MockERC20 public testToken;
    MockERC20 public usdcToken;
    MockFlashLoanProvider public provider;
    BorrowerExample public borrower;
    BadgeNFT public badge;
    
    address public deployer = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        // Deploy all contracts (simulating the deploy script)
        testToken = new MockERC20("Test Token", "TEST", 18, 1000000);
        usdcToken = new MockERC20("Mock USDC", "USDC", 6, 1000000);
        provider = new MockFlashLoanProvider();
        badge = new BadgeNFT("Flash Loan Master Badge", "FLMB", address(provider));
        borrower = new BorrowerExample();

        // Setup: Whitelist tokens
        provider.setTokenWhitelist(address(testToken), true);
        provider.setTokenWhitelist(address(usdcToken), true);

        // Setup: Add liquidity
        uint256 liquidityAmount = 100000 * 10**18;
        testToken.transfer(address(provider), liquidityAmount);
        
        uint256 usdcLiquidityAmount = 100000 * 10**6;
        usdcToken.transfer(address(provider), usdcLiquidityAmount);

        // Setup: Give borrower some funds for fees
        testToken.transfer(address(borrower), 1000 * 10**18);
        usdcToken.transfer(address(borrower), 1000 * 10**6);

        // Setup: Give some tokens to users for testing
        testToken.transfer(user1, 100 * 10**18);
        testToken.transfer(user2, 100 * 10**18);
    }

    function testFullFlashLoanFlow() public {
        uint256 borrowAmount = 5000 * 10**18;
        
        uint256 providerBalanceBefore = testToken.balanceOf(address(provider));
        uint256 borrowerBalanceBefore = testToken.balanceOf(address(borrower));
        
        // User1 executes a flash loan
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
        
        // Check balances - provider should have gained fee
        uint256 expectedFee = provider.calculateFee(borrowAmount);
        uint256 providerBalanceAfter = testToken.balanceOf(address(provider));
        uint256 borrowerBalanceAfter = testToken.balanceOf(address(borrower));
        
        assertEq(providerBalanceAfter, providerBalanceBefore + expectedFee);
        assertEq(borrowerBalanceAfter, borrowerBalanceBefore - expectedFee);
        
        // Check borrower tracked the transaction
        assertEq(borrower.totalFlashLoansReceived(address(testToken)), borrowAmount);
        assertGt(borrower.totalProfitGenerated(address(testToken)), 0);
        
        console.log("Flash loan completed successfully!");
        console.log("Fee paid:", expectedFee);
        console.log("Provider balance increase:", providerBalanceAfter - providerBalanceBefore);
        console.log("Borrower profit generated:", borrower.totalProfitGenerated(address(testToken)));
    }

    function testBadgeMinting() public {
        uint256 borrowAmount = 1000 * 10**18;
        
        // Execute flash loan first
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount,
            ""
        );
        
        // Mint badge for user1 (as the provider)
        vm.prank(address(provider));
        uint256 tokenId = badge.mintBadge(user1); 
        
        // Verify badge was minted
        assertTrue(badge.hasEarnedBadge(user1));
        assertEq(badge.ownerOf(tokenId), user1);
        assertEq(badge.totalBadgesMinted(), 1);
        assertEq(badge.getUserTokenId(user1), tokenId);
        
        // Try to mint another badge for same user (should fail)
        vm.prank(address(provider));
        vm.expectRevert("User already has a badge");
        badge.mintBadge(user1);
        
        console.log("Badge minted for user1, token ID:", tokenId);
    }

    function testMultipleUsersFlashLoans() public {
        uint256 borrowAmount1 = 1000 * 10**18;
        uint256 borrowAmount2 = 2000 * 10**18;
        
        // User1 executes flash loan
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount1,
            ""
        );
        
        // User2 executes flash loan
        vm.prank(user2);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            borrowAmount2,
            ""
        );
        
        // Check total borrowed and repaid
        assertEq(provider.totalBorrowed(address(testToken)), borrowAmount1 + borrowAmount2);
        
        uint256 expectedTotalRepaid = borrowAmount1 + provider.calculateFee(borrowAmount1)
                                    + borrowAmount2 + provider.calculateFee(borrowAmount2);
        assertEq(provider.totalRepaid(address(testToken)), expectedTotalRepaid);
        
        console.log("Multiple users completed flash loans successfully");
    }

    function testDifferentTokens() public {
        uint256 testTokenAmount = 1000 * 10**18;
        uint256 usdcAmount = 1000 * 10**6;
        
        // Flash loan with TEST token
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(testToken),
            testTokenAmount,
            ""
        );
        
        // Flash loan with USDC token
        vm.prank(user1);
        borrower.executeFlashLoan(
            address(provider),
            address(usdcToken),
            usdcAmount,
            ""
        );
        
        // Check both tokens were borrowed
        assertEq(borrower.totalFlashLoansReceived(address(testToken)), testTokenAmount);
        assertEq(borrower.totalFlashLoansReceived(address(usdcToken)), usdcAmount);
        
        console.log("Flash loans with different tokens completed successfully");
    }

    function testFeesAccumulation() public {
        uint256 initialProviderBalance = testToken.balanceOf(address(provider));
        uint256 borrowAmount = 1000 * 10**18;
        uint256 expectedFeePerLoan = provider.calculateFee(borrowAmount);
        
        // Execute multiple flash loans
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(address(uint160(100 + i))); // Different users
            borrower.executeFlashLoan(
                address(provider),
                address(testToken),
                borrowAmount,
                ""
            );
        }
        
        uint256 finalProviderBalance = testToken.balanceOf(address(provider));
        uint256 totalFeesCollected = finalProviderBalance - initialProviderBalance;
        uint256 expectedTotalFees = expectedFeePerLoan * 5;
        
        assertEq(totalFeesCollected, expectedTotalFees);
        
        console.log("Total fees collected:", totalFeesCollected);
        console.log("Expected fees:", expectedTotalFees);
    }

    function testAddLiquidityFromUser() public {
        uint256 addAmount = 50 * 10**18; // Reduced amount that user1 can afford
        uint256 providerBalanceBefore = testToken.balanceOf(address(provider));
        
        // User adds liquidity
        vm.startPrank(user1);
        testToken.approve(address(provider), addAmount);
        provider.addLiquidity(address(testToken), addAmount);
        vm.stopPrank();
        
        uint256 providerBalanceAfter = testToken.balanceOf(address(provider));
        assertEq(providerBalanceAfter, providerBalanceBefore + addAmount);
        
        console.log("User added liquidity:", addAmount);
    }
}
