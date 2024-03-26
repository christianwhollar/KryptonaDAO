const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("ProposalKryptonaChildModel", function () {
    let owner, addr1, addr2, addr3;
    let KryptonaDAO, kryptonaDAO;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let KryptonaTreasury, kryptonaTreasury, kryptonaTreasuryAddress;
    let KryptonaChildDAO, kryptonaChildDAO, kryptonaChildDAOAddress;
    let ProposalKryptonaChildModel, proposalKryptonaChildModel, proposalKryptonaChildModelAddress;
    let tokenURI;

    beforeEach(async function () {
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
        ProposalKryptonaChildModel = await ethers.getContractFactory("ProposalKryptonaChildModel");
        proposalKryptonaChildModel = await ProposalKryptonaChildModel.deploy(kryptonaChildDAOAddress);
        await proposalKryptonaChildModel.waitForDeployment();

        proposalKryptonaChildModelAddress = await proposalKryptonaChildModel.getAddress()

        // Assuming the DAO contract allows adding a proposal contract address
        await kryptonaChildDAO.setProposalContract(proposalKryptonaChildModelAddress);


        const tokenURIFilePath = path.join(__dirname, "../tokenURI/modelmetadatatokenuri.txt");
        const tokenURIData = fs.readFileSync(tokenURIFilePath, { encoding: "utf8" });
        tokenURI = tokenURIData.split("\n")[0];
    });

    it("Should mint an NFT with the correct tokenURI", async function () {
        // Read the tokenURI from the first line of the file
        await kryptonaChildDAO.addMember(addr1.address);
        await proposalKryptonaChildModel.connect(addr1).createModelProposal(addr2.address, 0);
        
        const proposalId = await proposalKryptonaChildModel.nextProposalId() - 1n;
        const proposal = await proposalKryptonaChildModel.proposals(proposalId);

        expect(proposal.description).to.equal("Add model");
    });

    it("Should execute an add model proposal successfully", async function () {
        await kryptonaChildDAO.addMember(addr1.address);

        await proposalKryptonaChildModel.connect(addr1).createModelProposal(tokenURI, 0);
        const proposalId = await proposalKryptonaChildModel.nextProposalId() - 1n;

        await proposalKryptonaChildModel.connect(addr1).vote(proposalId, true);

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); 
        await ethers.provider.send("evm_mine"); 
        
        await proposalKryptonaChildModel.connect(addr1).executeProposal(proposalId);
        
        const returnTokenURI = await kryptonaChildDAO.getTokenURI()
        expect(tokenURI).to.equal(returnTokenURI)
    });

    it("Should execute an update model proposal successfully", async function () {
        // Add model proposal required before update model
        await kryptonaChildDAO.addMember(addr1.address);

        await proposalKryptonaChildModel.connect(addr1).createModelProposal(tokenURI, 0);
        let proposalId = await proposalKryptonaChildModel.nextProposalId() - 1n;

        await proposalKryptonaChildModel.connect(addr1).vote(proposalId, true);

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); 
        await ethers.provider.send("evm_mine"); 
        
        await proposalKryptonaChildModel.connect(addr1).executeProposal(proposalId);
        
        let returnTokenURI = await kryptonaChildDAO.getTokenURI()
        expect(tokenURI).to.equal(returnTokenURI)

        // Continue to update model proposal
        // Change the value of the tokenURI
        tokenURI = tokenURI + "FAKEHASH"
        await proposalKryptonaChildModel.connect(addr1).createModelProposal(tokenURI, 1);
        proposalId = await proposalKryptonaChildModel.nextProposalId() - 1n;

        await proposalKryptonaChildModel.connect(addr1).vote(proposalId, true);

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); 
        await ethers.provider.send("evm_mine"); 
        
        await proposalKryptonaChildModel.connect(addr1).executeProposal(proposalId);
        
        returnTokenURI = await kryptonaChildDAO.getTokenURI()
        expect(tokenURI).to.equal(returnTokenURI)
    });
});
