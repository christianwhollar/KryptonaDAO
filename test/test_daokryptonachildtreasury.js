const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TreasuryChild", function (){
    let provider;
    let owner, addr1, addr2;
    let KryptonaTreasury, kryptonaTreasury, kryptonaTreasuryAddress;
    let ChildTreasury, childTreasury, childTreasuryAddress;
    let fee;

    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        provider = hre.ethers.provider;

        // Deploy Kryptona token contract
        Kryptona = await ethers.getContractFactory("Kryptona");
        kryptona = await Kryptona.deploy(1000000, 1000, 1); // Adjust parameters as needed
        await kryptona.waitForDeployment();

        // get token address
        kryptonaTokenAddress = await kryptona.getAddress()

        KryptonaTreasury = await ethers.getContractFactory("DAOKryptonaTreasury");
        kryptonaTreasury = await KryptonaTreasury.deploy(kryptonaTokenAddress);
        await kryptonaTreasury.waitForDeployment();

        kryptonaTreasuryAddress = kryptonaTreasury.getAddress();

        ChildTreasury = await ethers.getContractFactory("DAOKryptonaChildTreasury");
        childTreasury = await ChildTreasury.deploy(kryptonaTokenAddress, kryptonaTreasuryAddress);
        await childTreasury.waitForDeployment();

        childTreasuryAddress = childTreasury.getAddress();

        fee = 0.01;
    });

    it("should deposit tokens correctly and pay fee to parent treasury", async () => {
        const initialBalance = ethers.formatEther(await childTreasury.getETHBalance());
        expect(initialBalance).to.equal("0.0");

        const amountToSendString = "1.0";
        const amountToSend = ethers.parseEther(amountToSendString);

        const amountToReceive = String(parseFloat(amountToSendString) * (1 - fee))

        await addr1.sendTransaction({
            to: childTreasuryAddress,
            value: amountToSend
        });
        
        const finalBalance = ethers.formatEther(await childTreasury.getETHBalance());
        expect(finalBalance).to.equal(amountToReceive);
    });

    it("should withdrawal tokens correctly and pay fee to parent treasury", async () => {
        // get initial balance of wallet receiving deposit
        const initialWalletBalance = ethers.formatEther(await provider.getBalance(addr2.address));

        // declare amount to send
        const amountToSendString = "1.0";
        const amountToSend = ethers.parseEther(amountToSendString);

        // send ETH to child treasury
        await addr1.sendTransaction({
            to: childTreasuryAddress,
            value: amountToSend
        });

        // get initial balance of child treasury
        let childTreasuryInitialBalance = await childTreasury.getETHBalance();

        // withdrawal ETH from child treasury
        await childTreasury.withdrawEther(addr2.address, childTreasuryInitialBalance)

        // format child treasury balance to Ether
        childTreasuryInitialBalance = ethers.formatEther(childTreasuryInitialBalance)

        // get balance of child treasury after withdrawal
        let childTreasuryFinalBalance = await childTreasury.getETHBalance();
        childTreasuryFinalBalance = ethers.formatEther(childTreasuryFinalBalance)

        // get final balance of wallet receiving deposit
        const finalWalletBalance = ethers.formatEther(await provider.getBalance(addr2.address));

        // calculate expected balance using fee
        const expectedWalletBalance = parseFloat(childTreasuryInitialBalance) * (1 - fee);

        expect(finalWalletBalance - initialWalletBalance).to.closeTo(expectedWalletBalance, 0.01)
    });
});

