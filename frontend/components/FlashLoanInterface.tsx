'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACTS } from '../lib/contracts';
import { FLASH_LOAN_PROVIDER_ABI, ERC20_ABI } from '../lib/abis';

export default function FlashLoanInterface() {
  const { address, isConnected } = useAccount();
  const [amount, setAmount] = useState('');
  const [selectedToken, setSelectedToken] = useState('testToken');
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash, error } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess: isConfirmed } = 
    useWaitForTransactionReceipt({ hash });

  // Read token balances
  const { data: testTokenBalance } = useReadContract({
    address: CONTRACTS.testToken as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: usdcBalance } = useReadContract({
    address: CONTRACTS.usdcToken as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  // Read flash loan fee
  const { data: flashLoanFee } = useReadContract({
    address: CONTRACTS.flashLoanProvider as `0x${string}`,
    abi: FLASH_LOAN_PROVIDER_ABI,
    functionName: 'flashLoanFee',
  });

  const handleFlashLoan = async () => {
    if (!amount || !isConnected) return;

    setIsLoading(true);
    try {
      const tokenAddress = CONTRACTS[selectedToken as keyof typeof CONTRACTS];
      const amountWei = parseEther(amount);

      writeContract({
        address: CONTRACTS.flashLoanProvider as `0x${string}`,
        abi: FLASH_LOAN_PROVIDER_ABI,
        functionName: 'flashLoan',
        args: [tokenAddress, amountWei, CONTRACTS.borrowerExample, '0x'],
      });
    } catch (err) {
      console.error('Flash loan failed:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFaucet = async (token: string) => {
    if (!isConnected) return;

    try {
      const tokenAddress = CONTRACTS[token as keyof typeof CONTRACTS];
      writeContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'faucet',
      });
    } catch (err) {
      console.error('Faucet failed:', err);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-lg shadow-lg p-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Flash Loan Playground</h1>
          <ConnectButton />
        </div>

        {!isConnected ? (
          <div className="text-center py-12">
            <p className="text-gray-600 text-lg">Connect your wallet to get started</p>
          </div>
        ) : (
          <div className="space-y-8">
            {/* Account Info */}
            <div className="bg-blue-50 rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Your Balances</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-white rounded p-4">
                  <div className="flex justify-between items-center">
                    <span className="font-medium">Test Token</span>
                    <button 
                      onClick={() => handleFaucet('testToken')}
                      className="text-blue-600 hover:text-blue-800 text-sm"
                    >
                      Get from Faucet
                    </button>
                  </div>
                  <p className="text-2xl font-bold text-gray-900">
                    {testTokenBalance ? formatEther(testTokenBalance as bigint) : '0'} TEST
                  </p>
                </div>
                <div className="bg-white rounded p-4">
                  <div className="flex justify-between items-center">
                    <span className="font-medium">USDC Token</span>
                    <button 
                      onClick={() => handleFaucet('usdcToken')}
                      className="text-blue-600 hover:text-blue-800 text-sm"
                    >
                      Get from Faucet
                    </button>
                  </div>
                  <p className="text-2xl font-bold text-gray-900">
                    {usdcBalance ? formatEther(usdcBalance as bigint) : '0'} USDC
                  </p>
                </div>
              </div>
            </div>

            {/* Flash Loan Interface */}
            <div className="bg-gray-50 rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Execute Flash Loan</h2>
              <p className="text-gray-600 mb-6">
                Current Flash Loan Fee: {flashLoanFee ? `${flashLoanFee}%` : 'Loading...'}
              </p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Select Token
                  </label>
                  <select 
                    value={selectedToken}
                    onChange={(e) => setSelectedToken(e.target.value)}
                    className="w-full p-3 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="testToken">Test Token</option>
                    <option value="usdcToken">USDC Token</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Amount to Borrow
                  </label>
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="Enter amount"
                    className="w-full p-3 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <button
                  onClick={handleFlashLoan}
                  disabled={!amount || isLoading || isConfirming}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-md transition duration-200"
                >
                  {isLoading || isConfirming ? 'Processing...' : 'Execute Flash Loan'}
                </button>

                {hash && (
                  <div className="mt-4 p-4 bg-blue-100 rounded-md">
                    <p className="text-sm text-blue-800">
                      Transaction Hash: {hash}
                    </p>
                    {isConfirming && <p className="text-sm text-blue-600">Waiting for confirmation...</p>}
                    {isConfirmed && <p className="text-sm text-green-600">Transaction confirmed!</p>}
                  </div>
                )}

                {error && (
                  <div className="mt-4 p-4 bg-red-100 rounded-md">
                    <p className="text-sm text-red-800">
                      Error: {error.message}
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* How It Works */}
            <div className="bg-green-50 rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">How This Demo Works</h2>
              <div className="space-y-2 text-gray-700">
                <p>• Flash loans let you borrow tokens without collateral</p>
                <p>• You must repay the loan + fee in the same transaction</p>
                <p>• Our example contract simulates a profitable arbitrage strategy</p>
                <p>• Successfully completing flash loans earns you achievement badges</p>
                <p>• This is running on Monad testnet with mock tokens</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
