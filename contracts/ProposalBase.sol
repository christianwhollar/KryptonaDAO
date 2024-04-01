// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the abstract contract that defines the structure and functionality of proposals
import "./ProposalAbstract.sol";

/**
 * @title ProposalBase
 * @dev Implementation of the ProposalAbstract. Manages the creation, voting, and execution of proposals.
 */
contract ProposalBase is ProposalAbstract {

    /**
     * @dev Creates a new proposal with a descriptive text.
     * @param description A string containing the proposal's details.
     */
    function createProposal(string memory description) public override {
        // Increment nextProposalId and assign to proposalId
        uint256 proposalId = nextProposalId++;

        // Create a new proposal and store it in the mapping
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender, // Address of the proposer
            deadline: block.timestamp + 7 days, // Deadline set to 7 days from now
            executed: false, // Initially not executed
            forVotes: 0, // Initial votes in favor
            againstVotes: 0, // Initial votes against
            description: description // Proposal description
        });

        // Emit an event indicating proposal creation
        emit ProposalCreated(proposalId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific proposal.
     * @param proposalId The ID of the proposal to retrieve.
     * @return Tuple containing details of the proposal.
     */
    function getProposal(uint256 proposalId) public view returns (string memory, uint256, bool, uint256, uint256) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.deadline,
            proposal.executed,
            proposal.forVotes,
            proposal.againstVotes
        );
    }

    /**
     * @dev Allows voting on a proposal by incrementing either the forVotes or againstVotes count.
     * @param proposalId The ID of the proposal to vote on.
     * @param support A boolean indicating whether the vote is in support of the proposal.
     */
    function vote(uint256 proposalId, bool support) public virtual override {
        // Ensure the proposal is valid and voting is still open
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        // Access the proposal from storage
        Proposal storage p = proposals[proposalId];
        // Increment the appropriate vote counter based on the support parameter
        if (support) {
            p.forVotes++;
        } else {
            p.againstVotes++;
        }

        // Emit a voted event
        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal if it has more votes in favor than against and the deadline has passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public virtual override {
        Proposal storage proposal = proposals[proposalId];

        // Check that the voting period has ended and the proposal hasn't been executed yet
        require(block.timestamp >= proposal.deadline, "Voting is still active");
        require(!proposal.executed, "Proposal already executed");
        // Ensure the proposal passed
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");

        // Mark the proposal as executed
        proposal.executed = true;
    }

    /**
     * @dev Checks whether a proposal is valid (i.e., not executed and within the voting period).
     * @param proposalId The ID of the proposal to check.
     * @return True if the proposal is valid, otherwise false.
     */
    function _isProposalValid(uint256 proposalId) internal view override returns (bool) {
        Proposal memory p = proposals[proposalId];
        // A proposal is valid if it hasn't been executed and the deadline hasn't passed
        return (p.deadline > block.timestamp && !p.executed);
    }
}
