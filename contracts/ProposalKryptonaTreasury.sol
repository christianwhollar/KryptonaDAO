// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the base proposal contract and the main DAO contract
import "./ProposalBase.sol";
import "./DAOKryptona.sol";

/**
 * @title ProposalKryptonaTreasury
 * @dev Contract for managing treasury-related proposals within the DAO.
 * It extends ProposalBase to include functionalities specific to treasury fund management.
 */
contract ProposalKryptonaTreasury is ProposalBase {
    // Reference to the DAO contract for accessing DAO-specific functions
    DAOKryptona public dao;

    // Enumeration for the types of treasury-related proposals
    enum ProposalType { TransferFunds }

    // Struct to represent a treasury proposal, including fund transfer details
    struct TreasuryProposal {
        ProposalType proposalType; // The type of treasury proposal
        address payable to; // The recipient of the funds
        uint256 amount; // The amount to be transferred
    }

    // Mapping from proposal ID to its corresponding TreasuryProposal details
    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    /**
     * @dev Constructor sets the DAO contract address.
     * @param _dao Address of the DAOKryptona contract.
     */
    constructor(address _dao) {
        dao = DAOKryptona(_dao);
    }

    /**
     * @dev Overrides the vote function from ProposalBase to incorporate voting power from the DAO.
     * @param proposalId The ID of the proposal being voted on.
     * @param support Indicates whether the vote is in support of the proposal.
     */
    function vote(uint256 proposalId, bool support) public override {
        // Ensure the proposal is valid
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        // Retrieve the proposal and the voter's voting power
        Proposal storage p = proposals[proposalId];
        uint256 votingPower = dao.getVotingPower(msg.sender);

        // Apply the voting power to the proposal
        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        // Emit a voted event
        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Creates a new proposal for transferring funds from the DAO treasury.
     * @param _to The recipient of the funds.
     * @param _amount The amount to be transferred.
     * @param description A descriptive text for the proposal.
     */
    function createTreasuryProposal(address payable _to, uint256 _amount, string memory description) public {
        // Ensure the proposer is a DAO member and the amount is valid
        require(dao.checkMembership(msg.sender), "Only DAO members can propose");
        require(_amount > 0, "Invalid transfer amount");

        // Create a new proposal and assign it an ID
        uint256 proposalId = nextProposalId;
        createProposal(description);

        // Store the treasury proposal details
        treasuryProposals[proposalId] = TreasuryProposal({
            proposalType: ProposalType.TransferFunds,
            to: _to,
            amount: _amount
        });

        // Emit an event indicating the creation of a treasury proposal
        emit ProposalCreated(proposalId, msg.sender);
    }

    /**
     * @dev Executes a treasury proposal, transferring funds as specified.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public override {
        // Execute the base proposal logic first
        super.executeProposal(proposalId);

        // Retrieve the treasury proposal details
        TreasuryProposal storage tp = treasuryProposals[proposalId];

        // Perform the fund transfer as specified in the proposal
        dao.sendTreasuryFundsETH(tp.to, tp.amount);
    }
}
