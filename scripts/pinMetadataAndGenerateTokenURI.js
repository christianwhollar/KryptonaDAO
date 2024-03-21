require('dotenv').config();
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const pinJSONToIPFS = async (jsonContent) => {
    try {
        const res = await axios.post("https://api.pinata.cloud/pinning/pinJSONToIPFS", jsonContent, {
            headers: {
                'Authorization': `Bearer ${process.env.PINATA_JWT}`
            }
        });
        return res.data;
    } catch (error) {
        console.error(error);
        return null;
    }
};

// node ".\scripts\pinMetadataAndGenerateTokenURI.js" ".\ipfs\model.json"
async function main() {
    const jsonFilePath = process.argv[2];

    if (!jsonFilePath) {
        console.log("Usage: node scriptName <pathToJsonFile>");
        return;
    }

    try {
        const inputContent = fs.readFileSync(jsonFilePath, 'utf8');
        const { IpfsHash } = JSON.parse(inputContent);

        // Creating metadata
        const metadata = {
            description: "Metadata for my model",
            image: `ipfs://${IpfsHash}`
        };

        const metadataResponse = await pinJSONToIPFS(metadata);

        if (metadataResponse) {
            // Deriving output file names from the input file name
            const baseName = path.basename(jsonFilePath, path.extname(jsonFilePath));
            const metadataOutputPath = path.join(path.dirname(jsonFilePath), `${baseName}Metadata.json`);
            fs.writeFileSync(metadataOutputPath, JSON.stringify(metadataResponse, null, 2));
            console.log(`Metadata response written to ${metadataOutputPath}`);

            // Ensuring the tokenURI directory exists
            const tokenURIDir = path.join(__dirname, "../tokenURI");
            if (!fs.existsSync(tokenURIDir)){
                fs.mkdirSync(tokenURIDir);
            }
            
            // Writing the IPFS link of the metadata to a text file
            const tokenURITextPath = path.join(tokenURIDir, `${baseName}metadatatokenuri.txt`);
            const metadataIPFSUrl = `https://ipfs.io/ipfs/${metadataResponse.IpfsHash}`;
            fs.writeFileSync(tokenURITextPath, metadataIPFSUrl);
            console.log(`Metadata IPFS URL written to ${tokenURITextPath}`);
        } else {
            console.log("Failed to pin metadata to IPFS.");
        }
    } catch (error) {
        console.error(`Error processing file: ${error}`);
    }
}

main();
