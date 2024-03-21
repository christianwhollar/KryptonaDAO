// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProposalBase.sol";
import "./DAOKryptona.sol";

contract ProposalKryptonaTreasury is ProposalBase {
    DAOKryptona public dao;

    enum ProposalType { TransferFunds }
    struct TreasuryProposal {
        ProposalType proposalType;
        address payable to;
        uint256 amount;
    }

    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    constructor(address _dao) {
        dao = DAOKryptona(_dao);
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

    function createTreasuryProposal(address payable _to, uint256 _amount, string memory description) public {
        require(dao.checkMembership(msg.sender), "Only DAO members can propose");
        require(_amount > 0, "Invalid transfer amount");

        uint256 proposalId = nextProposalId;
        createProposal(description);

        treasuryProposals[proposalId] = TreasuryProposal({
            proposalType: ProposalType.TransferFunds,
            to: _to,
            amount: _amount
        });

        emit ProposalCreated(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) public override {
        super.executeProposal(proposalId);

        TreasuryProposal storage tp = treasuryProposals[proposalId];
        dao.sendTreasuryFundsETH(tp.to, tp.amount);
    }
}
