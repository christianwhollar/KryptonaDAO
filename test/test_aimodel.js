const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("AIModel Contract", function () {
    let AIModel;
    let aiModel;
    let owner;
    let addr1;

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        AIModel = await ethers.getContractFactory("AIModel");
        [owner, addr1] = await ethers.getSigners();

        // Deploy a new AIModel contract before each test.
        aiModel = await AIModel.deploy();
    });

    it("Should mint an NFT with the correct tokenURI", async function () {
        // Read the tokenURI from the first line of the file
        const tokenURIFilePath = path.join(__dirname, "../tokenURI/modelmetadatatokenuri.txt");
        const tokenURIData = fs.readFileSync(tokenURIFilePath, { encoding: "utf8" });
        const tokenURI = tokenURIData.split("\n")[0];
        console.log(tokenURI)
        // Mint a new NFT
        const mintTx = await aiModel.connect(owner).mintNFT(addr1.address, tokenURI);

        // Wait for the mint transaction to be mined
        await mintTx.wait();

        // Fetch the token URI of the newly minted NFT
        const newItemId = 1; 
        const mintedTokenURI = await aiModel.tokenURI(newItemId);

        // Compare the fetched token URI with the expected value
        expect(mintedTokenURI).to.equal(tokenURI);
    });
});
