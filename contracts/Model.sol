// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface IAIModel {
    function mintNFT(address recipient, string calldata tokenURI) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AIModel is ERC721URIStorage {
    uint256 private _currentTokenId = 0;
    mapping(string => bool) private _tokenURIsUsed;

    constructor() ERC721("AIModelNFT", "AIMMNFT") {}

    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        require(!_tokenURIsUsed[tokenURI], "Token URI already used.");

        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenURIsUsed[tokenURI] = true;

        return newItemId;
    }
}
