// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ProposalAbstract
 * @dev Abstract contract for managing proposals in a decentralized system.
 * It defines the basic structure and operations for proposals, including creation, voting, and execution.
 */
abstract contract ProposalAbstract {

    /**
     * @dev Struct to represent a proposal within the system.
     * @param id Unique identifier for the proposal.
     * @param proposer Address of the account that created the proposal.
     * @param deadline Timestamp indicating when the proposal voting period ends.
     * @param executed Boolean indicating whether the proposal has been executed.
     * @param forVotes Total number of votes in favor of the proposal.
     * @param againstVotes Total number of votes against the proposal.
     * @param description A descriptive text about the proposal.
     */
    struct Proposal {
        uint id;
        address proposer;
        uint256 deadline;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        string description;
    }

    // State variable to keep track of the ID for the next proposal
    uint256 public nextProposalId;
    // Mapping of proposal IDs to their corresponding Proposal structs
    mapping(uint256 => Proposal) public proposals;

    // Events
    event ProposalCreated(uint256 proposalId, address proposer);
    event Voted(uint256 proposalId, address voter, bool vote);

    /**
     * @dev Function to create a new proposal. Must be implemented by inheriting contract.
     * @param description Text description of what the proposal entails.
     */
    function createProposal(string memory description) public virtual;

    /**
     * @dev Function to cast a vote on a proposal. Must be implemented by inheriting contract.
     * @param proposalId The ID of the proposal being voted on.
     * @param vote The voter's decision (true for in favor, false for against).
     */
    function vote(uint256 proposalId, bool vote) public virtual;

    /**
     * @dev Function to execute a proposal after voting has ended. Must be implemented by inheriting contract.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public virtual;

    /**
     * @dev Internal function to check whether a proposal is valid (e.g., deadline has not passed, proposal exists).
     * Must be implemented by inheriting contract.
     * @param proposalId The ID of the proposal to check.
     * @return bool True if the proposal is valid, false otherwise.
     */
    function _isProposalValid(uint256 proposalId) internal view virtual returns (bool);
}
