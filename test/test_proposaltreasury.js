// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("Treasury and ProposalTreasury", function () {
//     let treasury, proposalTreasury;
//     let deployer, recipient;
//     const depositAmount = ethers.parseEther("10"); // 10 Ether for example

//     beforeEach(async function () {
//         // Deploy Treasury
//         const Treasury = await ethers.getContractFactory("Treasury");
//         treasury = await Treasury.deploy(/* kryptonaTreasuryAddress */);

//         // Deploy ProposalTreasury
//         const ProposalTreasury = await ethers.getContractFactory("ProposalTreasury");
//         proposalTreasury = await ProposalTreasury.deploy(treasury.address);

//         [deployer, recipient] = await ethers.getSigners();

//         // Assuming deployer is the owner of Treasury and makes a deposit
//         await treasury.connect(deployer).deposit({ value: depositAmount });
//     });

//     it("should create and execute a withdrawal proposal", async function () {
//         const withdrawAmount = ethers.parseEther("1"); // 1 Ether for example

//         // Create withdrawal proposal
//         await proposalTreasury.connect(deployer).createWithdrawalProposal(recipient.address, withdrawAmount);

//         // Vote for the proposal (assuming a simplified voting mechanism)
//         // In a real scenario, other addresses would vote
//         await proposalTreasury.connect(deployer).vote(0, true); // Voting for the proposal with id 0

//         // Fast forward time by 7 days to simulate proposal deadline passing
//         await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
//         await ethers.provider.send("evm_mine");

//         // Execute the withdrawal proposal
//         await proposalTreasury.connect(deployer).executeWithdrawalProposal(0);

//         // Verify recipient's balance increased
//         const recipientBalance = await ethers.provider.getBalance(recipient.address);
//         expect(recipientBalance).to.be.at.least(withdrawAmount);
//     });
// });
