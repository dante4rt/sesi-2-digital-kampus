import { ethers } from "hardhat";
import { TaskManager } from "../typechain-types";

async function main() {
    console.log("🚀 Starting TaskManager deployment to Monad Testnet...\n");

    // Get deployer account
    const [deployer] = await ethers.getSigners();
    console.log("📋 Deployment Details:");
    console.log("├── Deployer address:", deployer.address);

    // Check balance
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("├── Deployer balance:", ethers.formatEther(balance), "MON");

    if (balance < ethers.parseEther("0.01")) {
        console.log("⚠️  Warning: Low balance. Make sure you have enough MON for deployment.");
    }

    // Get network info
    const network = await ethers.provider.getNetwork();
    console.log("├── Network:", network.name);
    console.log("├── Chain ID:", network.chainId.toString());
    console.log("└── RPC URL:", "https://testnet-rpc.monad.xyz/\n");

    // Deploy TaskManager
    console.log("📦 Deploying TaskManager contract...");
    const TaskManagerFactory = await ethers.getContractFactory("TaskManager");

    // Estimate gas
    const deployTx = await TaskManagerFactory.getDeployTransaction();
    const estimatedGas = await ethers.provider.estimateGas(deployTx);
    console.log("├── Estimated gas:", estimatedGas.toString());

    // Deploy with manual gas limit (adding 20% buffer)
    const gasLimit = (estimatedGas * BigInt(120)) / BigInt(100);
    const taskManager: TaskManager = await TaskManagerFactory.deploy({
        gasLimit: gasLimit
    });

    console.log("├── Transaction hash:", taskManager.deploymentTransaction()?.hash);
    console.log("├── Waiting for deployment confirmation...");

    // Wait for deployment
    await taskManager.waitForDeployment();
    const contractAddress = await taskManager.getAddress();

    console.log("✅ TaskManager deployed successfully!");
    console.log("├── Contract address:", contractAddress);
    console.log("├── Block explorer:", `https://testnet.monadexplorer.com/address/${contractAddress}`);

    // Verify initial state
    console.log("\n🔍 Verifying initial contract state...");
    try {
        const owner = await taskManager.owner();
        const taskCount = await taskManager.taskCount();
        const userTaskCount = await taskManager.userTaskCount(deployer.address);

        console.log("├── Owner:", owner);
        console.log("├── Task count:", taskCount.toString());
        console.log("├── Deployer task count:", userTaskCount.toString());

        // Test calculateFee function
        const fee = await taskManager.calculateFee(100);
        console.log("└── Fee calculation (100 -> 2%):", fee.toString());

    } catch (error) {
        console.log("❌ Error verifying contract state:", error);
    }

    // Get deployment cost
    const deploymentTx = taskManager.deploymentTransaction();
    if (deploymentTx) {
        const receipt = await deploymentTx.wait();
        if (receipt) {
            const cost = receipt.gasUsed * receipt.gasPrice;
            console.log("\n💰 Deployment Cost:");
            console.log("├── Gas used:", receipt.gasUsed.toString());
            console.log("├── Gas price:", ethers.formatUnits(receipt.gasPrice, "gwei"), "gwei");
            console.log("└── Total cost:", ethers.formatEther(cost), "MON");
        }
    }

    // Provide next steps
    console.log("\n📋 Next Steps:");
    console.log("1. Save the contract address for future interactions");
    console.log("2. Verify the contract on block explorer (optional)");
    console.log("3. Test contract functions using Hardhat console or frontend");
    console.log("4. Add the contract to your MetaMask for easy interaction");

    // Save deployment info to file
    const deploymentInfo = {
        contractAddress: contractAddress,
        deployerAddress: deployer.address,
        network: network.name,
        chainId: network.chainId.toString(),
        blockExplorer: `https://testnet.monadexplorer.com/address/${contractAddress}`,
        timestamp: new Date().toISOString(),
        txHash: deploymentTx?.hash
    };

    // Write to file (optional)
    const fs = require('fs');
    const path = require('path');
    const deploymentsDir = path.join(__dirname, '..', 'deployments');

    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir);
    }

    fs.writeFileSync(
        path.join(deploymentsDir, 'taskmanager-monad-testnet.json'),
        JSON.stringify(deploymentInfo, null, 2)
    );

    console.log("\n💾 Deployment info saved to: deployments/taskmanager-monad-testnet.json");

    return {
        taskManager,
        contractAddress,
        deploymentInfo
    };
}

// Handle errors
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Deployment failed:");
        console.error(error);
        process.exit(1);
    });