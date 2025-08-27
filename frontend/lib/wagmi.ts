import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  arbitrum,
  base,
  mainnet,
  optimism,
  polygon,
  sepolia,
} from 'wagmi/chains';

// Add Monad testnet configuration
const monadTestnet = {
  id: 41454,
  name: 'Monad Testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'Monad',
    symbol: 'MON',
  },
  rpcUrls: {
    default: {
      http: ['https://testnet-rpc.monad.xyz'],
    },
  },
  blockExplorers: {
    default: { name: 'Monad Explorer', url: 'https://testnet-explorer.monad.xyz' },
  },
  testnet: true,
} as const;

export const config = getDefaultConfig({
  appName: 'Flash Loan Playground',
  projectId: 'YOUR_PROJECT_ID', // Get this from WalletConnect Cloud
  chains: [monadTestnet, sepolia, mainnet, optimism, arbitrum, polygon, base],
  ssr: true, // If your dApp uses server side rendering (SSR)
});
