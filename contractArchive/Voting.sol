// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Proposal {
        address payable recipient;
        uint256 amount;
        uint256 votesFor;
        bool executed;
    }

    Proposal[] public proposals;
    address public treasuryAddress;
    mapping(address => bool) public voters;

    constructor(address _treasury) {
        treasuryAddress = _treasury;
        voters[msg.sender] = true; // Initially, only the contract creator can vote. Modify as needed.
    }

    function addVoter(address voter) external {
        // Add logic to control who can add a voter, possibly only allowing the contract owner
        voters[voter] = true;
    }

    function createProposal(address payable recipient, uint256 amount) external {
        proposals.push(Proposal({
            recipient: recipient,
            amount: amount,
            votesFor: 0,
            executed: false
        }));
    }

    function vote(uint256 proposalId) external {
        require(voters[msg.sender], "Not a voter");
        Proposal storage proposal = proposals[proposalId];
        proposal.votesFor++; // This is a basic voting mechanism. Modify as needed.
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor > 1, "Insufficient votes"); // Define your criteria for proposal approval

        Treasury treasury = Treasury(treasuryAddress);
        treasury.withdraw(proposal.recipient, proposal.amount);
        proposal.executed = true;
    }
}
