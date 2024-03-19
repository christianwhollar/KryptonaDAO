const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("ProposalBase", function () {
    let proposalBase;

    beforeEach(async function () {
        const ProposalBase = await ethers.getContractFactory("ProposalBase");
        proposalBase = await ProposalBase.deploy();
        await proposalBase.waitForDeployment();
        [owner, addr1, addr2] = await ethers.getSigners();
    });

    it("create a proposal", async function () {
        // create proposal
        const description = "Test Proposal"
        const proposalID = 0
        await proposalBase.createProposal(description);

        // get proposal
        const proposal = await proposalBase.proposals(proposalID);

        // verify proposal description
        expect(proposal.description).to.equal(description);

    });

    it("vote on a proposal", async function () {
        // create proposal
        const description = "Test Proposal"
        const proposalID = 0
        await proposalBase.createProposal(description)

        // vote for proposal
        const vote = true;
        await proposalBase.vote(proposalID, vote);

        // get for votes
        const [, , , forVotes] = await proposalBase.getProposal(proposalID);

        // verify vote
        expect(forVotes).to.equal(1);
    });

    it("execute a proposal", async function () {
        // create proposal
        const description = "Test Proposal"
        const proposalID = 0
        await proposalBase.createProposal(description)
        
        // get proposal
        const proposal = await proposalBase.proposals(proposalID);

        // vote for proposal
        const vote = true;
        await proposalBase.vote(proposalID, vote);

        // fast forward to deadline
        const deadline = proposal.deadline
        await time.increaseTo(deadline)

        // execute proposal
        await proposalBase.executeProposal(proposalID);
        const proposalAfterExecution  = await proposalBase.proposals(proposalID);

        // verify proposal execution
        expect(proposalAfterExecution .executed).to.equal(true)
    })
});
