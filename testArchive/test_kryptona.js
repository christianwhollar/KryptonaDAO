//test/test_kryptona.js

const { expect } = require("chai");

describe("Kryptona Contract", function () {

  let Kryptona;
  let kryptona;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    Kryptona = await ethers.getContractFactory("Kryptona");
    kryptona = await Kryptona.deploy(1000000000, 1000000, 10);
    await kryptona.waitForDeployment();
    [owner, addr1, addr2] = await ethers.getSigners();
  })

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const ownerBalance = await kryptona.balanceOf(owner.address);
    expect(await kryptona.totalSupply()).to.equal(ownerBalance);
  });

  it("Should transfer tokens between accounts", async function () {
    await kryptona.transfer(addr1.address, 1000);
    const addr1Balance = await kryptona.balanceOf(addr1.address);
    expect(addr1Balance).to.equal(1000);

    await kryptona.connect(addr1).transfer(addr2.address, 100);
    const addr2Balance = await kryptona.balanceOf(addr2.address);
    expect(addr2Balance).to.equal(100);
  });

  it("Should create a proposal", async function () {
    await kryptona.createProposal("Test Proposal");
    const proposal = await kryptona.proposals(0);
    expect(proposal.description).to.equal("Test Proposal");
  });

  it("Should allow voting on a proposal", async function () {
    // Create a new proposal
    await kryptona.createProposal("Test Proposal");

    const proposalId = 0;
    const [, deadlineStr] = await kryptona.getProposal(proposalId);
    const deadline = BigInt(deadlineStr);

    // Get the current time from the blockchain
    const currentBlock = await ethers.provider.getBlock('latest');
    const currentTime = BigInt(currentBlock.timestamp);

    // Calculate the time to fast-forward to stay within the voting period
    const timeToAdvance = deadline - currentTime - BigInt(100); // 100 seconds before the deadline

    // Check and fast-forward the time if needed
    if (timeToAdvance > 0n) {
      await network.provider.send("evm_increaseTime", [timeToAdvance.toString()]);
      await network.provider.send("evm_mine"); // Mine a new block to apply the time change
    }

    // Proceed with voting
    await kryptona.connect(addr1).vote(proposalId, true);

    // Fetch the updated proposal details
    const [, , , forVotes] = await kryptona.getProposal(proposalId);

    // Check the votes
    expect(forVotes.toString()).to.equal((await kryptona.balanceOf(addr1.address)).toString());
  });

  it("Should execute a proposal", async function () {
    await kryptona.createProposal("Test Proposal");
    const proposalId = 0;

    await kryptona.transfer(addr1.address, 1000);

    await kryptona.connect(addr1).vote(proposalId, true);

    // Fast-forward time to surpass the proposal deadline
    await network.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // 7 days in seconds
    await network.provider.send("evm_mine");

    // Check that the proposal was executed
    // Execute the proposal
    await kryptona.executeProposal(proposalId);

    // Fetch the updated proposal details
    const [, , executed, forVotes, againstVotes] = await kryptona.getProposal(proposalId);
    expect(executed).to.be.true;
  });
})