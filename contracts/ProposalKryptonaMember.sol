// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing required contracts
import "./DAOKryptona.sol";
import "./ProposalBase.sol";

/**
 * @title ProposalKryptonaMember
 * @dev Manages proposals for adding or removing members in the DAO.
 */
contract ProposalKryptonaMember is ProposalBase {
    // Instance of the DAOKryptona contract to interact with the DAO
    DAOKryptona public dao;

    // Enumeration for proposal types specific to DAO membership
    enum ProposalType { AddMember, RemoveMember }

    // Structure for member proposals
    struct MemberProposal {
        ProposalType proposalType; // Type of the proposal (add or remove)
        address member; // Address of the member involved in the proposal
    }

    // Mapping of proposal IDs to their respective MemberProposal
    mapping(uint256 => MemberProposal) public memberProposals;

    /**
     * @dev Constructor to set the DAO contract address.
     * @param _dao Address of the DAOKryptona contract.
     */
    constructor(address _dao) {
        dao = DAOKryptona(_dao);
    }

    /**
     * @dev Allows voting on a proposal, considering the voting power of the voter.
     * @param proposalId ID of the proposal being voted on.
     * @param support Indicates whether the vote is in support (true) or against (false).
     */
    function vote(uint256 proposalId, bool support) public override {
        // Ensure the proposal is currently valid
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        // Retrieve the proposal and calculate the voter's voting power
        Proposal storage p = proposals[proposalId];
        uint256 votingPower = dao.getVotingPower(msg.sender);

        // Increment vote counts based on support
        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        // Emit an event indicating a vote has occurred
        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Creates a proposal to add or remove a member from the DAO.
     * @param _member Address of the member to be added or removed.
     * @param _type Type of the member proposal (add or remove).
     */
    function createMemberProposal(address _member, ProposalType _type) public {
        // Ensure only DAO members can create a proposal
        require(dao.checkMembership(msg.sender), "Only DAO members can propose");

        // Generate a new proposal ID
        uint256 proposalId = nextProposalId;
        // Create the proposal with a descriptive message
        createProposal(_type == ProposalType.AddMember ? "Add member" : "Remove member");

        // Record the member proposal details
        memberProposals[proposalId] = MemberProposal({
            proposalType: _type,
            member: _member
        });
    }

    /**
     * @dev Executes a proposal to add or remove a member, based on the proposal's outcome.
     * @param proposalId ID of the proposal to be executed.
     */
    function executeProposal(uint256 proposalId) public override {
        // Execute the proposal using the base logic
        super.executeProposal(proposalId);

        // Retrieve and execute the specific member proposal action
        MemberProposal storage mp = memberProposals[proposalId];
        if (mp.proposalType == ProposalType.AddMember) {
            // Add the member to the DAO
            dao.addMember(mp.member);
        } else if (mp.proposalType == ProposalType.RemoveMember) {
            // Remove the member from the DAO
            dao.removeMember(mp.member);
        }
    }
}
