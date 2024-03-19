// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KryptonaDAO is Ownable {
    ERC20 public kryptonaToken;
    address public proposalContract;

    struct Member {
        uint256 isMember;
        uint256 joinedAt;
        uint256 votingPower;
    }

    mapping(address => Member) public members;

    event MemberAdded(address member);
    event MemberRemoved(address member);

    constructor(address kryptonaTokenAddress) Ownable(msg.sender) {
        kryptonaToken = ERC20(kryptonaTokenAddress);
    }

    function setProposalContract(address _proposalContract) public onlyOwner {
        proposalContract = _proposalContract;
    }

    modifier onlyProposalContractOrOwner() {
        require(msg.sender == proposalContract || msg.sender == owner(), "Callable only by proposal contract or owner");
        _;
    }

    function addMember(address _member) public onlyProposalContractOrOwner {
        require(members[_member].isMember == 0, "Member already exists");
        uint256 balance = kryptonaToken.balanceOf(_member);
        require(balance > 0, "Insufficient Kryptona tokens");

        members[_member] = Member(1, block.timestamp, balance * 10);
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyProposalContractOrOwner {
        require(members[_member].isMember == 1, "Not a member");
        members[_member].isMember = 0;
        emit MemberRemoved(_member);
    }

    function checkMembership(address _member) public view returns (bool) {
        return members[_member].isMember == 1;
    }

    function getVotingPower(address _member) public view returns (uint256) {
        return members[_member].votingPower;
    }
}
