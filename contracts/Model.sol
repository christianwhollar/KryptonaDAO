// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing ERC721URIStorage for NFT functionality with URI storage
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @dev Interface for AI Model NFT interactions.
 */
interface IAIModel {
    // Function to mint a new NFT
    function mintNFT(address recipient, string calldata tokenURI) external returns (uint256);
    // Function to get the owner of a specific NFT by tokenId
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title AIModel
 * @dev Implementation of an NFT contract for AI models, extending ERC721URIStorage.
 */
contract AIModel is ERC721URIStorage {
    // Private state variable to keep track of the current token ID
    uint256 private _currentTokenId = 0;
    // Mapping to ensure each token URI is unique
    mapping(string => bool) private _tokenURIsUsed;

    /**
     * @dev Constructor initializing the ERC721 token with a name and symbol.
     */
    constructor() ERC721("AIModelNFT", "AIMMNFT") {}

    /**
     * @dev Public function to mint a new NFT. Ensures that each tokenURI is unique.
     * @param recipient The address to receive the NFT.
     * @param tokenURI The URI pointing to the token metadata.
     * @return newItemId The token ID of the minted NFT.
     */
    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        // Ensure the token URI has not been used previously
        require(!_tokenURIsUsed[tokenURI], "Token URI already used.");

        // Increment the current token ID for the new token
        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        
        // Mint the new token to the recipient and set its URI
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // Mark the token URI as used
        _tokenURIsUsed[tokenURI] = true;

        // Return the new token ID
        return newItemId;
    }
}
