// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Register {

    struct Model {
        uint256 id;
        string description;
        string modelURI;
    }

    uint256 public nextModelId;
    mapping(uint256 => Model) public models;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    function registerModel(string memory description, string memory modelURI) public onlyOwner {
        // Logic to register a new AI model
        
    }

}