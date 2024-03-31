// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProposalAbstract.sol";

contract ProposalBase is ProposalAbstract {

    function createProposal(string memory description) public override {
        uint256 proposalId = nextProposalId++; // Increment ID for next use after storing current value

        // Initialize and store the new proposal
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            deadline: block.timestamp + 7 days, // Setting a deadline 7 days from now
            executed: false,
            forVotes: 0,
            againstVotes: 0,
            description: description
        });

        emit ProposalCreated(proposalId, msg.sender); // Emit event with the current ID
    }

    function getProposal(uint256 proposalId) public view returns (string memory, uint256, bool, uint256, uint256) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.description, proposal.deadline, proposal.executed, proposal.forVotes, proposal.againstVotes);
    }

    function vote(uint256 proposalId, bool support) public virtual override {
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        Proposal storage p = proposals[proposalId];
        if (support) {
            p.forVotes++;
        } else {
            p.againstVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) public virtual override {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting is still active");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");

        proposal.executed = true; // Mark the proposal as executed
    }

    function _isProposalValid(uint256 proposalId) internal view override returns (bool) {
        Proposal memory p = proposals[proposalId];
        return (p.deadline > block.timestamp && !p.executed);
    }
}
