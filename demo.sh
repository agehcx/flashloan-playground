#!/bin/bash

# Flash Loan Playground Demo Script
# This script demonstrates the full flash loan flow

echo "🚀 Flash Loan Playground Demo"
echo "================================"

# Start local Anvil node in background
echo "📡 Starting local Anvil node..."
anvil --port 8545 --accounts 10 --balance 10000 &
ANVIL_PID=$!
sleep 3

# Set environment variables
export RPC_URL="http://127.0.0.1:8545"
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo "🔨 Deploying contracts..."
forge script script/Counter.s.sol:Deploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast > deployment.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    
    # Extract contract addresses (simplified - in real scenario would parse properly)
    echo "📄 Checking addresses.json..."
    if [ -f "addresses.json" ]; then
        cat addresses.json
    else
        echo "⚠️  addresses.json not found, but deployment completed"
    fi
    
    echo ""
    echo "🧪 Running tests..."
    forge test --match-contract IntegrationTest -v
    
    echo ""
    echo "📊 Gas report..."
    forge test --gas-report --match-contract IntegrationTest
    
else
    echo "❌ Deployment failed. Check deployment.log for details."
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
kill $ANVIL_PID 2>/dev/null
rm -f deployment.log

echo "Demo complete! 🎉"
