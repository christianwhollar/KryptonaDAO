const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("KryptonaTreasury:", function (){
    let provider;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let KryptonaTreasury, kryptonaTreasury, kryptonaTreasuryAddress;
    let owner, addr1;

    this.beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        provider = hre.ethers.provider;

        // Deploy Kryptona token contract
        Kryptona = await ethers.getContractFactory("Kryptona");
        kryptona = await Kryptona.deploy(1000000, 1000, 1); // Adjust parameters as needed
        await kryptona.waitForDeployment();

        // get token address
        kryptonaTokenAddress = await kryptona.getAddress()

        KryptonaTreasury = await ethers.getContractFactory("KryptonaTreasury");
        kryptonaTreasury = await KryptonaTreasury.deploy(kryptonaTokenAddress);
        await kryptonaTreasury.waitForDeployment();

        kryptonaTreasuryAddress = kryptonaTreasury.getAddress();
    });

    it("Should receive ETH deposit", async function () {
        //

        expect(await kryptonaTreasury.getETHBalance()).to.equal(0);
        const amountToSend = ethers.parseEther("1.0");

        await addr1.sendTransaction({
            to: kryptonaTreasuryAddress,
            value: amountToSend
        });

        const finalBalance = await kryptonaTreasury.getETHBalance();
        expect(finalBalance).to.equal(amountToSend);
    });

    it("Should withdraw ETH successfully", async function () {
        // Owner deposits ETH into the treasury for testing
        const amountToSend = ethers.parseEther("1.0");

        await owner.sendTransaction({
          to: kryptonaTreasuryAddress,
          value: amountToSend
        });

        // Pre-withdrawal ETH balance of the owner
        const initialBalance = await provider.getBalance(await owner.getAddress());

        // Withdraw 1 ETH from the treasury to the owner
        const withdrawAmount = ethers.parseEther("1.0");
        await kryptonaTreasury.connect(owner).sendETH(await owner.getAddress(), withdrawAmount);
    
        // Post-withdrawal ETH balance of the owner
        const finalBalance = await provider.getBalance(await owner.getAddress());

        // Assuming finalBalance, initialBalance, and withdrawAmount are BigNumber objects
        const balanceDifference = finalBalance - initialBalance;
        const expectedDifference = withdrawAmount; // Your expected amount in BigNumber format

        // Convert everything to ethers for a more human-readable comparison
        const balanceDifferenceInEther = ethers.formatEther(balanceDifference);
        const gasCostBuffer = 0.1;

        // Check if the actual difference is close to the expected difference, allowing for gas cost
        const isCloseToExpected = balanceDifferenceInEther < (1 + gasCostBuffer);

        expect(isCloseToExpected).to.be.true;
      });

})