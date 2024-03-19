// scripts/deploy_token.js

const hre = require("hardhat");

async function main() {
    const KrytonaToken = await hre.ethers.getContractFactory("Kryptona");
    const kryptonaToken = await KrytonaToken.deploy("1000000", "1000000", "1000000");

    await kryptonaToken.waitForDeployment();
    const address = await kryptonaToken.getAddress()

    console.log("Kryptona deployed to:", address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})