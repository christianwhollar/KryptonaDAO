require('dotenv').config();
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const pinFileToIPFS = async (src) => {
    const formData = new FormData();
    
    const file = fs.createReadStream(src);
    formData.append('file', file);
    
    const pinataMetadata = JSON.stringify({
        name: path.basename(src),
    });
    formData.append('pinataMetadata', pinataMetadata);
    
    const pinataOptions = JSON.stringify({
        cidVersion: 0,
    });
    formData.append('pinataOptions', pinataOptions);

    try {
        const res = await axios.post("https://api.pinata.cloud/pinning/pinFileToIPFS", formData, {
            maxBodyLength: "Infinity",
            headers: {
                'Content-Type': `multipart/form-data; boundary=${formData._boundary}`,
                'Authorization': `Bearer ${process.env.PINATA_JWT}`
            }
        });
        return res.data;
    } catch (error) {
        console.error(error);
        return null;
    }
};

// node ".\scripts\getToken.js"  "model" "./models/model.py"
async function main() {

    const jsonFileName = process.argv[2];
    const srcPath = process.argv[3];

    if (!jsonFileName || !srcPath) {
        console.log("Usage: node scriptName <jsonFileName> <srcPath>");
        return;
    }

    const response = await pinFileToIPFS(srcPath);

    if (response) {
        const outputPath = path.join(__dirname, `../ipfs/${jsonFileName}.json`);
        fs.writeFileSync(outputPath, JSON.stringify(response, null, 2));
        console.log(`Response written to ${outputPath}`);
    } else {
        console.log("Failed to pin file to IPFS.");
    }
}

main();
