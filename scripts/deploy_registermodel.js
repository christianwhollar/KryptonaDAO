// scripts/deploy_registermodel.js

const hre = require("hardhat");

async function main(){
    const RegisterModel = await hre.ethers.getContracts("RegisterModel");
    const registerModel = await RegisterModel.deploy("name", "symbol");

    await registerModel.waitForDeployment();
    const address = await RegisterModel.getAddress();

    console.log("Register model deployed to:", address);
    
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})