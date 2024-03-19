// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("Treasury", function () {
//     let Treasury;
//     let treasury;
//     let owner;

//     beforeEach(async function () {
//         [owner] = await ethers.getSigners();
//         Treasury = await ethers.getContractFactory("Treasury");
//         treasury = await Treasury.deploy();
//         await treasury.waitForDeployment();
//     });

//     it("should deploy successfully", async function () {
//         const treasuryAddress = await treasury.getAddress()
//         expect(treasuryAddress).to.be.properAddress;
//     });

//     it("should receive ether", async function () {
//         // get treasury address
//         const treasuryAddress = await treasury.getAddress()

//         // set amount to deposit
//         const amount = "1.0"

//         // send deposit transaction
//         const transactionHash = await owner.sendTransaction({
//             to: treasuryAddress,
//             value: ethers.parseEther(amount) // Sends exactly 1.0 ether
//         });

//         // verify deposit
//         await expect(transactionHash).to.changeEtherBalances([owner, treasury], [ethers.parseEther("-1.0"), ethers.parseEther("1.0")]);
//     });
// });
