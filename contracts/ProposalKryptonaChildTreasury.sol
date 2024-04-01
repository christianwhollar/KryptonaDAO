// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the ProposalBase for basic proposal functionality
// and the DAOKryptonaChild for DAO operations
import "./ProposalBase.sol";
import "./DAOKryptonaChild.sol";

/**
 * @title ProposalKryptonaChildTreasury
 * @dev Manages proposals related to treasury funds within the DAO.
 * Allows for the creation and execution of proposals to transfer funds from the DAO treasury.
 */
contract ProposalKryptonaChildTreasury is ProposalBase {
    // Reference to the DAO child contract for accessing DAO-specific functions
    DAOKryptonaChild public daoChild;

    // Enumeration for the types of treasury-related proposals
    enum ProposalType { TransferFunds }

    // Struct to represent a treasury proposal, including details for fund transfers
    struct TreasuryProposal {
        ProposalType proposalType; // The type of treasury proposal
        address payable to; // The recipient of the transfer
        uint256 amount; // The amount to be transferred
    }

    // Mapping from proposal ID to its corresponding TreasuryProposal details
    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    /**
     * @dev Constructor to set the DAO child contract address.
     * @param _daoChild Address of the DAOKryptonaChild contract.
     */
    constructor(address _daoChild) {
        daoChild = DAOKryptonaChild(_daoChild);
    }

    /**
     * @dev Overrides the vote function from ProposalBase to include voting power from the DAO child.
     * @param proposalId The ID of the proposal being voted on.
     * @param support Boolean indicating if the vote is in support of the proposal.
     */
    function vote(uint256 proposalId, bool support) public override {
        // Ensure the proposal is still valid
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        // Retrieve the proposal and the voter's voting power
        Proposal storage p = proposals[proposalId];
        uint256 votingPower = daoChild.getVotingPower(msg.sender);

        // Apply the voting power to the proposal votes
        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        // Emit a voted event
        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Creates a proposal for transferring funds from the DAO treasury.
     * @param _to The recipient of the funds.
     * @param _amount The amount to be transferred.
     * @param description A descriptive text for the proposal.
     */
    function createTreasuryProposal(address payable _to, uint256 _amount, string memory description) public {
        // Ensure the proposer is a DAO member and the amount is valid
        require(daoChild.checkMembership(msg.sender), "Only DAO members can propose");
        require(_amount > 0, "Invalid transfer amount");

        // Create a new proposal with a description
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
     * @dev Overrides the executeProposal function from ProposalBase to perform treasury fund transfers.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public override {
        // Execute the base proposal logic first
        super.executeProposal(proposalId);

        // Retrieve the treasury proposal details
        TreasuryProposal storage tp = treasuryProposals[proposalId];

        // Perform the fund transfer as specified in the proposal
        daoChild.sendTreasuryFundsETH(tp.to, tp.amount);
    }
}
