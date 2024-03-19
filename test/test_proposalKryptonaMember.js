const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProposalKryptonaMember", function () {
    let KryptonaDAO, kryptonaDAO, kryptonaDAOAddress;
    let ProposalKryptonaMember, proposalKryptonaMember, proposalKryptonaMemberAddress;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let owner, addr1, addr2, addr3;

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

        // Deploy KryptonaDAO contract with Kryptona token address
        KryptonaDAO = await ethers.getContractFactory("KryptonaDAO");
        kryptonaDAO = await KryptonaDAO.deploy(kryptonaTokenAddress);
        await kryptonaDAO.waitForDeployment();

        kryptonaDAOAddress = await kryptonaDAO.getAddress()

        // Set up ProposalKryptonaMember with the DAO address
        ProposalKryptonaMember = await ethers.getContractFactory("ProposalKryptonaMember");
        proposalKryptonaMember = await ProposalKryptonaMember.deploy(kryptonaDAOAddress);
        await proposalKryptonaMember.waitForDeployment();

        proposalKryptonaMemberAddress = await proposalKryptonaMember.getAddress()

        // Assuming the DAO contract allows adding a proposal contract address
        await kryptonaDAO.setProposalContract(proposalKryptonaMemberAddress);
    });

    it("Should create a member proposal", async function () {
        await kryptonaDAO.addMember(addr1.address);
        await proposalKryptonaMember.connect(addr1).createMemberProposal(addr2.address, 0);
        
        const proposalId = await proposalKryptonaMember.nextProposalId() - 1n;
        const proposal = await proposalKryptonaMember.proposals(proposalId);

        expect(proposal.description).to.equal("Add member");
    });

    it("Should execute an add member proposal successfully", async function () {
        await kryptonaDAO.addMember(addr1.address);
    
        await proposalKryptonaMember.connect(addr1).createMemberProposal(addr2.address, 0); // 0 for AddMember
        const proposalId = await proposalKryptonaMember.nextProposalId() - 1n;
    
        await proposalKryptonaMember.connect(addr1).vote(proposalId, true);
    
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");
    
        await proposalKryptonaMember.connect(addr1).executeProposal(proposalId);
    
        const isMember = await kryptonaDAO.checkMembership(addr2.address);
        expect(isMember).to.equal(true);
    });

    it("Should execute a remove member proposal successfully", async function () {
        await kryptonaDAO.addMember(addr1.address);
        await kryptonaDAO.addMember(addr2.address);
    
        let isMemberBeforeRemoval = await kryptonaDAO.checkMembership(addr2.address);
        expect(isMemberBeforeRemoval).to.equal(true);
    
        await proposalKryptonaMember.connect(addr1).createMemberProposal(addr2.address, 1);
        const proposalId = await proposalKryptonaMember.nextProposalId() - 1n;
    
        await proposalKryptonaMember.connect(addr1).vote(proposalId, true);
    
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");
    
        await proposalKryptonaMember.connect(addr1).executeProposal(proposalId);
    
        const isMemberAfterRemoval = await kryptonaDAO.checkMembership(addr2.address);
        expect(isMemberAfterRemoval).to.equal(false);
    });

    it("Should handle votes correctly with addr1 voting for and addr2 voting against", async function () {
        await kryptonaDAO.addMember(addr1.address);
    
        let isMemberBeforeProposal = await kryptonaDAO.checkMembership(addr3.address);
        expect(isMemberBeforeProposal).to.equal(false);
    
        await proposalKryptonaMember.connect(addr1).createMemberProposal(addr3.address, 0);
        const proposalId = await proposalKryptonaMember.nextProposalId() - 1n;
    
        await proposalKryptonaMember.connect(addr1).vote(proposalId, true);
    
        await proposalKryptonaMember.connect(addr2).vote(proposalId, false); 
    
        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); 
        await ethers.provider.send("evm_mine"); 

        await proposalKryptonaMember.connect(addr1).executeProposal(proposalId);
        
        const isMemberAfterProposal = await kryptonaDAO.checkMembership(addr3.address);
        expect(isMemberAfterProposal).to.equal(true);
    });

});
