const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProposalKryptonaTreasury", function () {
    let KryptonaDAO, kryptonaDAO, kryptonaDAOAddress;
    let ProposalKryptonaTreasury, proposalKryptonaTreasury, proposalKryptonaTreasuryAddress;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let KryptonaTreasury, kryptonaTreasury, kryptonaTreasuryAddress;
    let owner, addr1, addr2, addr3;
    let provider;
    beforeEach(async function () {
        provider = hre.ethers.provider;
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        // Deploy Kryptona token contract
        Kryptona = await ethers.getContractFactory("Kryptona");
        kryptona = await Kryptona.deploy(1000000, 1000, 1); // Adjust parameters as needed
        await kryptona.waitForDeployment();

        // get token address
        kryptonaTokenAddress = await kryptona.getAddress()

        // Mint Kryptona tokens to addr1 and addr2
        await kryptona.mint(addr1.address, 1000);
        await kryptona.mint(addr2.address, 100);
        await kryptona.mint(addr3.address, 100);

        // deploy kryptona treasury
        KryptonaTreasury = await ethers.getContractFactory("KryptonaTreasury");
        kryptonaTreasury = await KryptonaTreasury.deploy(kryptonaTokenAddress);
        await kryptonaTreasury.waitForDeployment();

        kryptonaTreasuryAddress = await kryptonaTreasury.getAddress();

        // Deploy KryptonaDAO contract with Kryptona token address
        KryptonaDAO = await ethers.getContractFactory("DAOKryptona");
        kryptonaDAO = await KryptonaDAO.deploy(kryptonaTokenAddress, kryptonaTreasuryAddress);
        await kryptonaDAO.waitForDeployment();

        kryptonaDAOAddress = await kryptonaDAO.getAddress()

        // Set up ProposalKryptonaMember with the DAO address
        ProposalKryptonaTreasury = await ethers.getContractFactory("ProposalKryptonaTreasury");
        proposalKryptonaTreasury = await ProposalKryptonaTreasury.deploy(kryptonaDAOAddress);
        await proposalKryptonaTreasury.waitForDeployment();

        proposalKryptonaTreasuryAddress = await proposalKryptonaTreasury.getAddress()

        // Assuming the DAO contract allows adding a proposal contract address
        await kryptonaDAO.setProposalContract(proposalKryptonaTreasuryAddress);
    });

    it("should send ETH to the treasury and execute a proposal", async function() {
        expect(await kryptonaTreasury.getETHBalance()).to.equal(0);

        await kryptonaDAO.addMember(addr1.address);
        const amountToSend = ethers.parseEther("1.0");
        const initialEthBalance = await provider.getBalance(await addr2.getAddress());

        // Send ETH to the treasury
        await kryptonaDAO.connect(addr1).contributeToTreasuryETH({ value: amountToSend });


        // Check initial balance of the treasury in ETH
        await proposalKryptonaTreasury.connect(addr1).createTreasuryProposal(addr2.address, amountToSend, "Send to Address 2");
        const proposalId = await proposalKryptonaTreasury.nextProposalId() - 1n;
        // Vote on the proposal (assuming addr1 can vote)
        await proposalKryptonaTreasury.connect(addr1).vote(proposalId, true);

        // Simulate time passage for the proposal to become executable
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");
    
        // Execute the proposal
        await proposalKryptonaTreasury.connect(addr1).executeProposal(proposalId);

        const finalEthBalance = await provider.getBalance(await addr2.getAddress());
        const ethReceived = ethers.formatEther(finalEthBalance - initialEthBalance);
        expect(ethReceived).to.equal(ethers.formatEther(amountToSend));
    });
});