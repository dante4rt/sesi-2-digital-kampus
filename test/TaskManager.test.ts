import { expect } from "chai";
import { ethers } from "hardhat";
import { TaskManager } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("TaskManager", function () {
    let taskManager: TaskManager;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    // Hook yang dijalankan sebelum setiap test
    beforeEach(async function () {
        // Mendapatkan signers (akun test)
        [owner, user1, user2] = await ethers.getSigners();

        // Deploy contract baru untuk setiap test
        const TaskManagerFactory = await ethers.getContractFactory("TaskManager");
        taskManager = await TaskManagerFactory.deploy();
        await taskManager.waitForDeployment();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await taskManager.owner()).to.equal(owner.address);
        });

        it("Should initialize taskCount to 0", async function () {
            expect(await taskManager.taskCount()).to.equal(0);
        });

        it("Should initialize userTaskCount to 0 for any address", async function () {
            expect(await taskManager.userTaskCount(user1.address)).to.equal(0);
            expect(await taskManager.userTaskCount(user2.address)).to.equal(0);
        });
    });

    describe("View Functions", function () {
        it("Should return correct owner address", async function () {
            const ownerAddress = await taskManager.getOwner();
            expect(ownerAddress).to.equal(owner.address);
        });

        it("Should calculate fee correctly", async function () {
            // Test dengan berbagai nilai
            expect(await taskManager.calculateFee(100)).to.equal(2); // 2% dari 100 = 2
            expect(await taskManager.calculateFee(1000)).to.equal(20); // 2% dari 1000 = 20
            expect(await taskManager.calculateFee(50)).to.equal(1); // 2% dari 50 = 1
        });

        it("Should handle edge cases for calculateFee", async function () {
            expect(await taskManager.calculateFee(0)).to.equal(0);
            expect(await taskManager.calculateFee(1)).to.equal(0); // 1 * 2 / 100 = 0 (integer division)
        });
    });

    describe("Add Task Function", function () {
        it("Should add task successfully", async function () {
            // Tambah task dari user1
            await taskManager.connect(user1).addTask();

            // Verify taskCount bertambah
            expect(await taskManager.taskCount()).to.equal(1);

            // Verify userTaskCount bertambah untuk user1
            expect(await taskManager.userTaskCount(user1.address)).to.equal(1);
        });

        it("Should allow multiple users to add tasks", async function () {
            // User1 tambah 2 tasks
            await taskManager.connect(user1).addTask();
            await taskManager.connect(user1).addTask();

            // User2 tambah 1 task
            await taskManager.connect(user2).addTask();

            // Verify counts
            expect(await taskManager.taskCount()).to.equal(3);
            expect(await taskManager.userTaskCount(user1.address)).to.equal(2);
            expect(await taskManager.userTaskCount(user2.address)).to.equal(1);
        });

        it("Should track individual user task counts correctly", async function () {
            // User1 tambah 5 tasks
            for (let i = 0; i < 5; i++) {
                await taskManager.connect(user1).addTask();
            }

            // User2 tambah 3 tasks
            for (let i = 0; i < 3; i++) {
                await taskManager.connect(user2).addTask();
            }

            // Verify individual counts
            expect(await taskManager.userTaskCount(user1.address)).to.equal(5);
            expect(await taskManager.userTaskCount(user2.address)).to.equal(3);
            expect(await taskManager.taskCount()).to.equal(8);
        });

        it("Should emit no events (TaskManager doesn't have events)", async function () {
            // Karena contract tidak memiliki events, kita hanya test bahwa transaction berhasil
            const tx = await taskManager.connect(user1).addTask();
            const receipt = await tx.wait();

            // Verify transaction was successful
            expect(receipt?.status).to.equal(1);
        });
    });

    describe("Gas Usage", function () {
        it("Should use reasonable gas for addTask", async function () {
            const tx = await taskManager.connect(user1).addTask();
            const receipt = await tx.wait();

            // Gas usage untuk addTask harus reasonable (< 100k gas)
            expect(receipt?.gasUsed).to.be.lessThan(100000);

            console.log(`Gas used for addTask: ${receipt?.gasUsed.toString()}`);
        });

        it("Should use no gas for view functions when called directly", async function () {
            // View functions tidak menggunakan gas ketika dipanggil langsung
            const owner = await taskManager.getOwner();
            const fee = await taskManager.calculateFee(100);

            expect(owner).to.be.a('string');
            expect(fee).to.equal(2);
        });
    });

    describe("Edge Cases", function () {
        it("Should handle large numbers in calculateFee", async function () {
            const largeNumber = ethers.parseEther("1000000"); // 1M ETH in wei
            const expectedFee = largeNumber * BigInt(2) / BigInt(100);

            expect(await taskManager.calculateFee(largeNumber)).to.equal(expectedFee);
        });

        it("Should maintain state correctly after many operations", async function () {
            // Simulasi penggunaan intensif
            const iterations = 10;

            for (let i = 0; i < iterations; i++) {
                await taskManager.connect(user1).addTask();
                await taskManager.connect(user2).addTask();
            }

            expect(await taskManager.taskCount()).to.equal(iterations * 2);
            expect(await taskManager.userTaskCount(user1.address)).to.equal(iterations);
            expect(await taskManager.userTaskCount(user2.address)).to.equal(iterations);
        });
    });

    describe("Contract State Consistency", function () {
        it("Should maintain consistency between total and individual counts", async function () {
            const users = [user1, user2, owner];
            let totalExpected = 0;

            // Setiap user tambah task dengan jumlah berbeda
            for (let i = 0; i < users.length; i++) {
                const tasksToAdd = i + 1; // user1: 1, user2: 2, owner: 3
                for (let j = 0; j < tasksToAdd; j++) {
                    await taskManager.connect(users[i]).addTask();
                }
                totalExpected += tasksToAdd;
            }

            // Verify total count
            expect(await taskManager.taskCount()).to.equal(totalExpected);

            // Verify individual counts
            let totalFromUsers = 0;
            for (let i = 0; i < users.length; i++) {
                const userCount = await taskManager.userTaskCount(users[i].address);
                totalFromUsers += Number(userCount);
                expect(userCount).to.equal(i + 1);
            }

            // Total dari semua user harus sama dengan taskCount
            expect(totalFromUsers).to.equal(totalExpected);
        });
    });
});