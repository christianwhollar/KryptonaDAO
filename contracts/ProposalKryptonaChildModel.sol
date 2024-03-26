// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProposalBase.sol";
import "./DAOKryptonaChild.sol";

contract ProposalKryptonaChildModel is ProposalBase {
    DAOKryptonaChild public dao;

    enum ProposalType { AddModel, UpdateModel }
    struct ProposalModel {
        ProposalType proposalType;
        string tokenURI;
    }

    mapping(uint256 => ProposalModel) public modelProposals;

    constructor(address _dao) {
        dao = DAOKryptonaChild(_dao);
    }

    function vote(uint256 proposalId, bool support) public override {
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        Proposal storage p = proposals[proposalId];
        uint256 votingPower = dao.getVotingPower(msg.sender);

        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function createModelProposal(string memory _tokenURI, ProposalType _type) public {
        require(dao.checkMembership(msg.sender), "Only DAO members can propose");

        uint256 proposalId = nextProposalId;
        createProposal(_type == ProposalType.AddModel ? "Add model" : "Update model");
        modelProposals[proposalId] = ProposalModel({
            proposalType: _type,
            tokenURI: _tokenURI
        });

        emit ProposalCreated(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) public override {
        super.executeProposal(proposalId);
        
        ProposalModel storage mp = modelProposals[proposalId];
        
        if (mp.proposalType == ProposalType.AddModel) {
            dao.addModel(mp.tokenURI);
        } else if (mp.proposalType == ProposalType.UpdateModel) {
            dao.updateModel(mp.tokenURI);
        }
    }
}
