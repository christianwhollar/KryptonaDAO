// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ProposalAbstract {
    struct Proposal {
        address proposer;
        uint256 deadline;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // Declare storage for the next proposal id
    uint256 public nextProposalId;

    // Declare storage for proposals
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 proposalId, address proposer);
    event Voted(uint256 proposalId, address voter, bool vote);

    function createProposal() public virtual;
    function vote(uint256 proposalId, bool vote) public virtual;
    function executeProposal(uint256 proposalId) public virtual;
    function _isProposalValid(uint256 proposalId) internal view virtual returns (bool);
}
