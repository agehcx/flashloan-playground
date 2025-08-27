# Flash Loan Playground Frontend

This directory will contain the Next.js frontend for the Flash Loan Playground.

## Planned Features

- **🔗 Wallet Connection**: RainbowKit integration
- **💱 Token Selection**: Dropdown for TEST/USDC tokens  
- **💰 Amount Input**: Flash loan amount with balance validation
- **⚡ Execute Button**: One-click flash loan execution
- **📊 Results Display**: Transaction status, fees, profits
- **🏆 Badge Display**: NFT badge showcase
- **📈 Stats Dashboard**: Total volume, successful loans, leaderboard

## Tech Stack

- **Framework**: Next.js 14 + TypeScript
- **Styling**: Tailwind CSS + Tailwind Forms
- **Web3**: Wagmi + Viem + RainbowKit
- **State**: TanStack Query for server state
- **Icons**: Heroicons
- **Fonts**: Inter

## Quick Start

```bash
cd frontend
npm install
npm run dev
```

## Components Structure

```
components/
├── layout/
│   ├── Header.tsx           # Navigation + wallet connect
│   └── Footer.tsx           # Links and info
├── flash-loan/
│   ├── TokenSelector.tsx    # TEST/USDC dropdown
│   ├── AmountInput.tsx      # Amount + max button
│   ├── ExecuteButton.tsx    # Main CTA
│   └── ResultCard.tsx       # Transaction results
├── badge/
│   ├── BadgeCard.tsx        # NFT badge display
│   └── BadgeModal.tsx       # Badge details modal
└── dashboard/
    ├── StatsCard.tsx        # Metrics display
    └── LeaderboardTable.tsx # Top users
```

## State Management

```typescript
// hooks/useFlashLoan.ts
export function useFlashLoan() {
  const { data: contracts } = useContracts()
  const { writeContract } = useWriteContract()
  
  const executeFlashLoan = useMutation({
    mutationFn: async ({ token, amount }: FlashLoanParams) => {
      return writeContract({
        address: contracts.borrower,
        abi: borrowerAbi,
        functionName: 'executeFlashLoan',
        args: [contracts.provider, token, amount, '0x']
      })
    }
  })
  
  return { executeFlashLoan }
}
```

## Environment Variables

```bash
# .env.local
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_CHAIN_ID=41998  # Monad testnet
NEXT_PUBLIC_RPC_URL=https://testnet-rpc.monad.xyz
```

---

**To implement the frontend:**

1. Run `npm install` in this directory
2. Copy contract addresses from `../addresses.json`
3. Add contract ABIs to `lib/abis/`
4. Implement components step by step
5. Test with deployed contracts

**The frontend is designed to be a simple, clean interface that showcases the flash loan functionality without overwhelming complexity.**
