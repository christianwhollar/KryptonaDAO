// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing contracts for interaction
import "./DAOKryptonaChild.sol";
import "./ProposalBase.sol";

/**
 * @title ProposalKryptonaChildMember
 * @dev Extension of ProposalBase to support member management proposals in a DAO.
 * Allows DAO members to propose adding or removing members.
 */
contract ProposalKryptonaChildMember is ProposalBase {
    // Reference to the DAO contract to interact with
    DAOKryptonaChild public daoChild;

    // Enum for proposal types specific to DAO member management
    enum ProposalType { AddMember, RemoveMember }

    // Struct for holding member proposal details
    struct MemberProposal {
        ProposalType proposalType; // Type of the proposal (add or remove member)
        address member; // Address of the member involved in the proposal
    }

    // Mapping of proposal IDs to their corresponding MemberProposal details
    mapping(uint256 => MemberProposal) public memberProposals;

    /**
     * @dev Constructor to set the DAO contract address.
     * @param _daoChild Address of the DAOKryptonaChild contract.
     */
    constructor(address _daoChild) {
        daoChild = DAOKryptonaChild(_daoChild);
    }

    /**
     * @dev Overrides the vote function from ProposalBase to account for DAO voting power in proposals.
     * @param proposalId The ID of the proposal being voted on.
     * @param support Boolean indicating if the vote is in support of the proposal.
     */
    function vote(uint256 proposalId, bool support) public override {
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        Proposal storage p = proposals[proposalId];
        uint256 votingPower = daoChild.getVotingPower(msg.sender); // Retrieve voter's voting power from the DAO

        // Apply voting power to the proposal
        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        // Emit a voted event with the vote details
        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Creates a proposal for adding or removing a member from the DAO.
     * @param _member Address of the member to be added or removed.
     * @param _type ProposalType indicating whether to add or remove the member.
     */
    function createMemberProposal(address _member, ProposalType _type) public {
        // Check if proposer is a DAO member
        require(daoChild.checkMembership(msg.sender), "Only DAO members can propose");

        uint256 proposalId = nextProposalId;
        // Use inherited function to create a generic proposal
        createProposal(_type == ProposalType.AddMember ? "Add member" : "Remove member");

        // Store the member proposal details
        memberProposals[proposalId] = MemberProposal({
            proposalType: _type,
            member: _member
        });
    }

    /**
     * @dev Overrides the executeProposal function from ProposalBase to perform member management actions.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public override {
        // Execute the generic proposal logic first
        super.executeProposal(proposalId);

        MemberProposal storage mp = memberProposals[proposalId];
        // Execute specific actions based on proposal type
        if (mp.proposalType == ProposalType.AddMember) {
            daoChild.addMember(mp.member); // Add the member to the DAO
        } else if (mp.proposalType == ProposalType.RemoveMember) {
            daoChild.removeMember(mp.member); // Remove the member from the DAO
        }
    }
}
