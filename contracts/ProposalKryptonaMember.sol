// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAOKryptona.sol";
import "./ProposalBase.sol";

contract ProposalKryptonaMember is ProposalBase {
    DAOKryptona public dao;

    enum ProposalType { AddMember, RemoveMember }

    struct MemberProposal {
        ProposalType proposalType;
        address member;
    }

    mapping(uint256 => MemberProposal) public memberProposals;

    constructor(address _dao) {
        dao = DAOKryptona(_dao);
    }

    function vote(uint256 proposalId, bool support) public override {
        require(_isProposalValid(proposalId), "Invalid or expired proposal");

        Proposal storage p = proposals[proposalId];
        uint256 votingPower = dao.getVotingPower(msg.sender); // Assuming such a function exists

        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function createMemberProposal(address _member, ProposalType _type) public {
        require(dao.checkMembership(msg.sender), "Only DAO members can propose");

        uint256 proposalId = nextProposalId;
        createProposal(_type == ProposalType.AddMember ? "Add member" : "Remove member");

        memberProposals[proposalId] = MemberProposal({
            proposalType: _type,
            member: _member
        });
    }

    function executeProposal(uint256 proposalId) public override {
        super.executeProposal(proposalId);

        MemberProposal storage mp = memberProposals[proposalId];
        if (mp.proposalType == ProposalType.AddMember) {
            dao.addMember(mp.member);
        } else if (mp.proposalType == ProposalType.RemoveMember) {
            dao.removeMember(mp.member);
        }
    }
}
