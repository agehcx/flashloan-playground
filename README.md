## Flash Loan Playground on Monad (EVM Testnet)

![Flash Loan Playground](https://img.shields.io/badge/Status-Ready-green)
![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue)
![Foundry](https://img.shields.io/badge/Foundry-Latest-red)

> **Flash Loan Playground on Monad lets builders test atomic loan logic in a safe, deterministic environment. One click borrows, runs a mock strategy, repays, and mints a proof-of-completion badge. It showcases Monad's EVM speed and dev-friendliness while giving teams a forkable template for real strategies later.**

## 🚀 Quick Start (60 seconds)

```bash
# 1. Clone and setup
git clone <this-repo>
cd flash-loan-playground
cp .env.example .env

# 2. Edit .env with your private key
# PRIVATE_KEY=0x...

# 3. Install dependencies
forge install

# 4. Run tests
forge test -vv

# 5. Deploy to Monad testnet
forge script script/Counter.s.sol:Deploy --rpc-url $RPC_URL_MONAD_TESTNET --broadcast

# 6. Check addresses.json for deployed contracts
cat addresses.json
```

## 📋 What This Does

This is a **complete flash loan playground** that demonstrates:

1. **Borrowing** test tokens via `MockFlashLoanProvider` 
2. **Executing** atomic operations (mock arbitrage/yield strategies)
3. **Repaying** within the same transaction with fees
4. **Minting** NFT badges for successful completion
5. **Tracking** all operations transparently

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  MockERC20      │    │ MockFlashLoan   │    │  BorrowerExample│
│  (TEST/USDC)    │◄──►│  Provider       │◄──►│  (Template)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │  BadgeNFT       │
                       │  (Achievements) │
                       └─────────────────┘
```

## 🏗️ Contracts

### Core Contracts

| Contract | Description | Features |
|----------|-------------|----------|
| `MockFlashLoanProvider` | Flash loan provider | Configurable fees, whitelisting, liquidity management |
| `MockERC20` | Test tokens (TEST, USDC) | Faucet, mint/burn, standard ERC20 |
| `BorrowerExample` | Template borrower | Mock profit generation, fee payment |
| `BadgeNFT` | Achievement system | Soulbound tokens, one per user |

### Key Features

- **Configurable Fees**: Default 0.3% (30 bps), max 10%
- **Token Whitelisting**: Only approved tokens can be borrowed
- **Deterministic Profits**: Mock arbitrage for testing
- **Gas Optimized**: Single transaction for borrow → profit → repay
- **Event Tracking**: Full audit trail of all operations

## 🧪 Testing

```bash
# Run all tests
forge test

# Run specific test suites
forge test test/Provider.t.sol -v
forge test test/Borrower.t.sol -v  
forge test test/Integration.t.sol -v

# Run with gas reporting
forge test --gas-report

# Run integration tests with logs
forge test test/Integration.t.sol -vv
```

### Test Coverage

- ✅ **Unit Tests**: All contracts tested individually
- ✅ **Integration Tests**: Full end-to-end scenarios
- ✅ **Security Tests**: Malicious borrower protection
- ✅ **Edge Cases**: Insufficient funds, invalid tokens
- ✅ **Fee Math**: Precise calculations verified

## 📊 Usage Examples

### Basic Flash Loan

```solidity
// 1. Deploy contracts
MockFlashLoanProvider provider = new MockFlashLoanProvider();
BorrowerExample borrower = new BorrowerExample();

// 2. Setup
provider.setTokenWhitelist(address(token), true);
token.transfer(address(provider), 100000 * 10**18); // Add liquidity

// 3. Execute flash loan
borrower.executeFlashLoan(
    address(provider),
    address(token), 
    1000 * 10**18,  // 1000 tokens
    ""
);
```

### Using Cast Commands

```bash
# Check available liquidity
cast call $PROVIDER "getAvailableLiquidity(address)" $TEST_TOKEN --rpc-url $RPC_URL

# Calculate fee for amount
cast call $PROVIDER "calculateFee(uint256)" 1000000000000000000000 --rpc-url $RPC_URL

# Execute flash loan
cast send $BORROWER "executeFlashLoan(address,address,uint256,bytes)" \
  $PROVIDER $TEST_TOKEN 1000000000000000000000 0x \
  --private-key $PRIVATE_KEY --rpc-url $RPC_URL
```

## 🔧 Development Setup

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- Node.js 16+ (for frontend)
- Git

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Required variables:
PRIVATE_KEY=0x...                    # Your deployer private key
RPC_URL_MONAD_TESTNET=https://...    # Monad testnet RPC
```

### Deploy to Monad Testnet

```bash
# Make sure you have testnet ETH
forge script script/Counter.s.sol:Deploy \
  --rpc-url $RPC_URL_MONAD_TESTNET \
  --broadcast \
  --verify

# Addresses will be saved to addresses.json
```

## 📁 Project Structure

```
├── src/
│   ├── MockERC20.sol              # Test tokens
│   ├── MockFlashLoanProvider.sol  # Flash loan logic
│   ├── BorrowerExample.sol        # Template borrower
│   ├── BadgeNFT.sol              # Achievement NFTs
│   └── IFlashBorrower.sol        # Interface
├── script/
│   └── Counter.s.sol             # Deployment script
├── test/
│   ├── Provider.t.sol            # Provider tests
│   ├── Borrower.t.sol            # Borrower tests
│   └── Integration.t.sol         # End-to-end tests
├── addresses.json                # Deployed contracts
└── foundry.toml                  # Config
```

## 🎯 Example Scenarios

### 1. Arbitrage Simulation

```solidity
// Mock arbitrage between DEX A and DEX B
function mockArbitrage(uint256 amount) internal returns (uint256 profit) {
    // Simulate:
    // 1. Borrow USDC
    // 2. Swap USDC → ETH on DEX A
    // 3. Swap ETH → USDC on DEX B (at better rate)
    // 4. Keep profit, repay loan
    
    profit = (amount * mockProfitBasisPoints) / 10000;
    return profit;
}
```

### 2. Liquidation Simulation

```solidity
// Mock liquidation scenario
function mockLiquidation(address collateral, uint256 debt) internal {
    // Simulate:
    // 1. Borrow USDC to repay user's debt
    // 2. Seize collateral at discount
    // 3. Sell collateral for USDC
    // 4. Keep discount as profit
}
```

### 3. Yield Farming Flash

```solidity
// Mock yield farming optimization
function mockYieldFarm(uint256 amount) internal {
    // Simulate:
    // 1. Borrow large amount
    // 2. Deposit in high-yield farm
    // 3. Harvest rewards instantly
    // 4. Withdraw and repay
}
```

## 🏆 Badge System

Users earn **non-transferable NFT badges** for completing flash loans:

- **Flash Loan Master**: First successful flash loan
- **Badge Properties**:
  - Soulbound (non-transferable)
  - On-chain metadata
  - Unique per user
  - Proof of achievement

## 🔒 Security Features

- **Reentrancy Protection**: All functions protected
- **Input Validation**: Comprehensive checks
- **Balance Verification**: Strict repayment enforcement
- **Access Controls**: Role-based permissions
- **Fee Limits**: Maximum 10% fee protection

## 🚨 Known Limitations

- **Test Environment**: Not for production use
- **Mock Profits**: Simulated, not real arbitrage
- **Single Chain**: Monad testnet only
- **No Oracles**: Deterministic pricing only

## 📈 Gas Costs

| Operation | Gas Cost |
|-----------|----------|
| Flash Loan | ~130,000 |
| Badge Mint | ~83,000 |
| Add Liquidity | ~38,000 |
| Token Transfer | ~51,000 |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Add tests for your changes
4. Ensure all tests pass: `forge test`
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README
- **Issues**: GitHub Issues tab
- **Tests**: Run `forge test -vv` for debugging
- **Community**: Monad Discord

## 🎉 Acknowledgments

- **Monad Team**: For the blazing-fast EVM
- **Foundry**: For excellent tooling
- **OpenZeppelin**: For secure contract standards

---

**Ready to flash loan like a pro? Deploy and start experimenting! 🚀**
