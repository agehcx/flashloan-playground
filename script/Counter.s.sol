// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "../src/MockFlashLoanProvider.sol";
import "../src/BorrowerExample.sol";
import "../src/BadgeNFT.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockERC20 tokens
        MockERC20 testToken = new MockERC20(
            "Test Token",
            "TEST",
            18,
            1000000 // 1M initial supply
        );

        MockERC20 usdcToken = new MockERC20(
            "Mock USDC",
            "USDC",
            6,
            1000000 // 1M initial supply with 6 decimals
        );

        // Deploy Flash Loan Provider
        MockFlashLoanProvider provider = new MockFlashLoanProvider();

        // Deploy Badge NFT
        BadgeNFT badge = new BadgeNFT(
            "Flash Loan Master Badge",
            "FLMB",
            address(provider)
        );

        // Deploy Borrower Example
        BorrowerExample borrower = new BorrowerExample();

        // Setup: Whitelist tokens in provider
        provider.setTokenWhitelist(address(testToken), true);
        provider.setTokenWhitelist(address(usdcToken), true);

        // Setup: Add initial liquidity to provider
        uint256 liquidityAmount = 100000 * 10**18; // 100k TEST tokens
        testToken.transfer(address(provider), liquidityAmount);
        
        uint256 usdcLiquidityAmount = 100000 * 10**6; // 100k USDC tokens
        usdcToken.transfer(address(provider), usdcLiquidityAmount);

        // Setup: Give borrower some initial funds for fees
        testToken.transfer(address(borrower), 1000 * 10**18);
        usdcToken.transfer(address(borrower), 1000 * 10**6);

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("=== Flash Loan Playground Deployment ===");
        console.log("Test Token (TEST):", address(testToken));
        console.log("Mock USDC:", address(usdcToken));
        console.log("Flash Loan Provider:", address(provider));
        console.log("Badge NFT:", address(badge));
        console.log("Borrower Example:", address(borrower));
        console.log("=========================================");

        // Write addresses to file for frontend
        string memory addresses = string(
            abi.encodePacked(
                '{\n',
                '  "testToken": "', _addressToString(address(testToken)), '",\n',
                '  "usdcToken": "', _addressToString(address(usdcToken)), '",\n',
                '  "flashLoanProvider": "', _addressToString(address(provider)), '",\n',
                '  "badgeNFT": "', _addressToString(address(badge)), '",\n',
                '  "borrowerExample": "', _addressToString(address(borrower)), '"\n',
                '}'
            )
        );

        vm.writeFile("./addresses.json", addresses);
        console.log("Addresses written to addresses.json");
    }

    function _addressToString(address addr) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}
