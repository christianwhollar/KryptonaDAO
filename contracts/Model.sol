// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract AIModel is ERC721URIStorage {

    uint256 private _currentTokenId = 0;

    constructor() ERC721("AIModelNFT", "AIMMNFT"){}

    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        _currentTokenId += 1;
        uint256 newItemId = _currentTokenId;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

}