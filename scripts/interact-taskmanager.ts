import { ethers } from "hardhat";

async function main() {
    // Replace with your deployed contract address
    const CONTRACT_ADDRESS = "0x7713060cD603A419d83D951130B086e6063E96Ae";

    const [signer] = await ethers.getSigners();
    console.log("Interacting with contract as:", signer.address);

    // Get contract instance
    const TaskManager = await ethers.getContractFactory("TaskManager");
    const taskManager = TaskManager.attach(CONTRACT_ADDRESS);

    // Read current state
    console.log("\n📊 Current State:");
    console.log("Owner:", await taskManager.owner());
    console.log("Total tasks:", (await taskManager.taskCount()).toString());
    console.log("Your tasks:", (await taskManager.userTaskCount(signer.address)).toString());

    // Add a task
    console.log("\n➕ Adding a task...");
    const tx = await taskManager.addTask();
    await tx.wait();
    console.log("Task added! Transaction:", tx.hash);

    // Read updated state
    console.log("\n📊 Updated State:");
    console.log("Total tasks:", (await taskManager.taskCount()).toString());
    console.log("Your tasks:", (await taskManager.userTaskCount(signer.address)).toString());

    // Test fee calculation
    console.log("\n🧮 Fee Calculations:");
    console.log("Fee for 100:", (await taskManager.calculateFee(100)).toString());
    console.log("Fee for 1000:", (await taskManager.calculateFee(1000)).toString());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});