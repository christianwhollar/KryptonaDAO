const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProposalKryptonaChildTreasury", function () {
    let provider;
    let owner, addr1, addr2, addr3;
    let KryptonaDAO, kryptonaDAO;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let KryptonaTreasury, kryptonaTreasury, kryptonaTreasuryAddress;
    let KryptonaChildDAO, kryptonaChildDAO, kryptonaChildDAOAddress;
    let ProposalKryptonaChildTreasury, proposalKryptonaChildTreasury, proposalKryptonaChildTreasuryAddress;
    let fee;

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

        //
        KryptonaTreasury = await ethers.getContractFactory("KryptonaTreasury");
        kryptonaTreasury = await KryptonaTreasury.deploy(kryptonaTokenAddress);
        await kryptonaTreasury.waitForDeployment();

        kryptonaTreasuryAddress = await kryptonaTreasury.getAddress();

        // Deploy KryptonaDAO contract with Kryptona token address
        KryptonaDAO = await ethers.getContractFactory("DAOKryptona");
        kryptonaDAO = await KryptonaDAO.deploy(kryptonaTokenAddress, kryptonaTreasuryAddress);
        await kryptonaDAO.waitForDeployment();

        //
        KryptonaChildDAO = await ethers.getContractFactory("DAOKryptonaChild");
        kryptonaChildDAO = await KryptonaChildDAO.deploy(kryptonaTokenAddress, kryptonaTreasuryAddress);
        await kryptonaChildDAO.waitForDeployment();

        kryptonaChildDAOAddress = await kryptonaChildDAO.getAddress()

        // Set up ProposalKryptonaMember with the DAO address
        ProposalKryptonaChildTreasury = await ethers.getContractFactory("ProposalKryptonaChildTreasury");
        proposalKryptonaChildTreasury = await ProposalKryptonaChildTreasury.deploy(kryptonaChildDAOAddress);
        await proposalKryptonaChildTreasury.waitForDeployment();

        proposalKryptonaChildTreasuryAddress = await proposalKryptonaChildTreasury.getAddress()

        // Assuming the DAO contract allows adding a proposal contract address
        await kryptonaChildDAO.setProposalContract(proposalKryptonaChildTreasuryAddress);

        fee = 0.01;
    });

    it("should send ETH to the treasury and execute a proposal", async function() {

        await kryptonaChildDAO.addMember(addr1.address);

        const initialBalanceChild = ethers.formatEther(await kryptonaChildDAO.getETHBalance());
        expect(initialBalanceChild).to.equal("0.0");

        const initialBalanceAddr = await provider.getBalance(await addr2.getAddress());

        const amountToSendString = "1.0";
        const amountToSend = ethers.parseEther(amountToSendString);

        const amountToReceiveChild = String(parseFloat(amountToSendString) * (1 - fee))

        await kryptonaChildDAO.connect(addr1).contributeToTreasuryETH({ value: amountToSend });
        
        const finalBalanceChild = await kryptonaChildDAO.getETHBalance();
        const amountToReceiveAddr = String(parseFloat(finalBalanceChild) * (1 - fee))

        await proposalKryptonaChildTreasury.connect(addr1).createTreasuryProposal(addr2.address, finalBalanceChild, "Send to Address 2");
        const proposalId = await proposalKryptonaChildTreasury.nextProposalId() - 1n;

        await proposalKryptonaChildTreasury.connect(addr1).vote(proposalId, true);

        // Simulate time passage for the proposal to become executable
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await proposalKryptonaChildTreasury.connect(addr1).executeProposal(proposalId);

        const finalBalanceAddr = await provider.getBalance(await addr2.getAddress());
        expect(finalBalanceAddr - initialBalanceAddr).to.equal(amountToReceiveAddr)
    });
});
