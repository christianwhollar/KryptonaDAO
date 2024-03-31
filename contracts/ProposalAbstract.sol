// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ProposalAbstract {

    // Proposal structure
    struct Proposal {
        uint id;
        address proposer;
        uint256 deadline;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        string description;
    }

    // State variables
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Events
    event ProposalCreated(uint256 proposalId, address proposer);
    event Voted(uint256 proposalId, address voter, bool vote);

    // Function declarations
    function createProposal(string memory description) public virtual;
    function vote(uint256 proposalId, bool vote) public virtual;
    function executeProposal(uint256 proposalId) public virtual;
    function _isProposalValid(uint256 proposalId) internal view virtual returns (bool);
}
