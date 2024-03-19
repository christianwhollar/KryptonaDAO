const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("KryptonaDAO", function () {

    let KryptonaDAO, kryptonaDAO;
    let Kryptona, kryptona, kryptonaTokenAddress;
    let owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy Kryptona token contract
        Kryptona = await ethers.getContractFactory("Kryptona");
        kryptona = await Kryptona.deploy(1000000, 1000, 1); // Adjust parameters as needed
        await kryptona.waitForDeployment();

        // get token address
        kryptonaTokenAddress = await kryptona.getAddress()

        // Mint Kryptona tokens to addr1 and addr2
        await kryptona.mint(addr1.address, 100);
        await kryptona.mint(addr2.address, 100);

        // Deploy KryptonaDAO contract with Kryptona token address
        KryptonaDAO = await ethers.getContractFactory("KryptonaDAO");
        kryptonaDAO = await KryptonaDAO.deploy(kryptonaTokenAddress);
        await kryptonaDAO.waitForDeployment();
    });

    it("Should add a member successfully", async function () {
        // add addr1 as a member
        await kryptonaDAO.addMember(addr1.address);

        // get member struct by address
        const member = await kryptonaDAO.members(addr1.address);

        // verify addr1 is a member of kryptona dao
        expect(member.isMember).to.equal(1);
    });

    it("Should remove a member successfully", async function () {
        // add addr1 as a member
        await kryptonaDAO.addMember(addr1.address);
        let member = await kryptonaDAO.members(addr1.address);

        // verify addr1 is a member of kryptona dao
        expect(member.isMember).to.equal(1);

        // remove addr1 as a member
        await kryptonaDAO.removeMember(addr1.address);
        member = await kryptonaDAO.members(addr1.address);

        // verify addr1 removal
        expect(member.isMember).to.equal(0);
    });

    it("Should not allow non-owner to add members", async function () {
        try {
            // attempt to add addr1 as a member by addr2
            await kryptonaDAO.connect(addr1).addMember(addr2.address);

            // fail expected
            expect.fail("Transaction did not revert with any error");
        } catch (error) {
            // verify error
            expect(error.message).to.include("Callable only by proposal contract or owner");
        }
    });

    it("Verify voting power of added member", async function () {
        // add addr1 as a member
        await kryptonaDAO.addMember(addr1.address);

        // get member struct by address
        const member = await kryptonaDAO.members(addr1.address);

        // get kryptona balance of addr1
        const balance = await kryptona.balanceOf(addr1.address)

        // verify voting power
        expect(member.votingPower).to.equal(balance * 10n)
    });
});
