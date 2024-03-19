// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProposalBase.sol";

contract Treasury {
    address public owner;
    address payable public kryptonaTreasuryAddress;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    constructor(address payable _kryptonaTreasuryAddress) {
        owner = msg.sender;
        kryptonaTreasuryAddress = _kryptonaTreasuryAddress;
    }

    receive() external payable {
        // calculate fee
        uint256 fee = msg.value / 100;

        // trasnfer fee to kryptona treasury
        kryptonaTreasuryAddress.transfer(fee);

        // emit event
        emit Deposit(msg.sender, msg.value - fee);
    }

    function deposit() external payable {
        // calculate fee
        uint256 fee = msg.value / 100;

        // transfer fee to kryptona address
        kryptonaTreasuryAddress.transfer(fee);

        // deposit fee to krytpona treasury
        emit Deposit(msg.sender, msg.value - fee);
    }

    function withdraw(address payable to, uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 fee = amount / 100;
        uint256 amountAfterFee = amount - fee;
        require(address(this).balance >= amount, "Insufficient balance");
        kryptonaTreasuryAddress.transfer(fee);
        to.transfer(amountAfterFee);
        emit Withdrawal(to, amountAfterFee);
    }
}

contract ProposalTreasury is ProposalBase {
    Treasury public treasury;

    struct TreasuryAction {
        address payable recipient;
        uint256 amount;
    }

    mapping(uint256 => TreasuryAction) public treasuryActions;

    constructor(address payable _treasuryAddress) {
        treasury = Treasury(_treasuryAddress);
    }

    function createWithdrawalProposal(address payable _recipient, uint256 _amount) public {
        uint256 proposalId = nextProposalId++;
        Proposal storage p = proposals[proposalId];
        p.proposer = msg.sender;
        p.deadline = block.timestamp + 7 days;

        treasuryActions[proposalId] = TreasuryAction({
            recipient: _recipient,
            amount: _amount
        });

        emit ProposalCreated(proposalId, msg.sender);
    }

    function executeWithdrawalProposal(uint256 proposalId) public {
        require(_isProposalValid(proposalId), "Invalid or expired proposal");
        Proposal storage p = proposals[proposalId];
        require(p.forVotes > p.againstVotes, "Proposal did not pass");
        require(!p.executed, "Proposal already executed");

        TreasuryAction memory action = treasuryActions[proposalId];
        treasury.withdraw(action.recipient, action.amount);

        p.executed = true;
    }
}
