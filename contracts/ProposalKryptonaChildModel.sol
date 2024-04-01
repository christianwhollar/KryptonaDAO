// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the base proposal contract and the DAO child contract
import "./ProposalBase.sol";
import "./DAOKryptonaChild.sol";

/**
 * @title ProposalKryptonaChildModel
 * @dev Extends ProposalBase to manage proposals related to AI models in the DAO.
 * This contract allows creating proposals to add or update AI models in the DAO.
 */
contract ProposalKryptonaChildModel is ProposalBase {
    // Reference to the DAO child contract
    DAOKryptonaChild public daoChild;

    // Enumeration for the types of proposals handled by this contract
    enum ProposalType { AddModel, UpdateModel }

    // Struct to represent a proposal related to an AI model
    struct ProposalModel {
        ProposalType proposalType; // The type of the model proposal (add or update)
        string tokenURI; // The URI for the model's token metadata
    }

    // Mapping from proposal ID to the corresponding model proposal
    mapping(uint256 => ProposalModel) public modelProposals;

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
     * @dev Creates a proposal related to an AI model, either to add or update it.
     * @param _tokenURI The URI of the model's token metadata.
     * @param _type The type of proposal (add or update).
     */
    function createModelProposal(string memory _tokenURI, ProposalType _type) public {
        // Ensure the proposer is a DAO member
        require(daoChild.checkMembership(msg.sender), "Only DAO members can propose");

        // Create a new proposal
        uint256 proposalId = nextProposalId;
        createProposal(_type == ProposalType.AddModel ? "Add model" : "Update model");
        
        // Store the model proposal details
        modelProposals[proposalId] = ProposalModel({
            proposalType: _type,
            tokenURI: _tokenURI
        });

        // Emit an event indicating the creation of a model proposal
        emit ProposalCreated(proposalId, msg.sender);
    }

    /**
     * @dev Overrides the executeProposal function from ProposalBase to perform model management actions.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public override {
        // Execute the base proposal logic first
        super.executeProposal(proposalId);
        
        // Retrieve the model proposal details
        ProposalModel storage mp = modelProposals[proposalId];
        
        // Execute actions based on the proposal type
        if (mp.proposalType == ProposalType.AddModel) {
            daoChild.addModel(mp.tokenURI); // Add a new model
        } else if (mp.proposalType == ProposalType.UpdateModel) {
            daoChild.updateModel(mp.tokenURI); // Update an existing model
        }
    }
}
