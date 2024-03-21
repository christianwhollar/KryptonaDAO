// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./KryptonaTreasury.sol";
import "./TreasuryChild.sol";

contract DAOKryptonaChild is Ownable {
    ERC20 public kryptonaToken;
    KryptonaTreasury public kryptonaTreasury;
    TreasuryChild public childTreasury;
    address public proposalContract;
    
    struct Member {
        bool isMember;
        uint256 joinedAt;
        uint256 votingPower;
    }

    mapping(address => Member) public members;

    event MemberAdded(address member);
    event MemberRemoved(address member);
    event TreasuryFunded(uint256 amount);

    constructor(address _kryptonaTokenAddress, address payable _kryptonaTreasury) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
        kryptonaTreasury = new KryptonaTreasury(_kryptonaTreasury);
        childTreasury = new TreasuryChild(_kryptonaTokenAddress, _kryptonaTreasury);
    }

    function setProposalContract(address _proposalContract) public onlyOwner {
        proposalContract = _proposalContract;
    }

    modifier onlyProposalContractOrOwner() {
        require(msg.sender == proposalContract || msg.sender == owner(), "Callable only by proposal contract or owner");
        _;
    }

    function addMember(address _member) public onlyProposalContractOrOwner {
        require(!members[_member].isMember, "Member already exists");
        uint256 balance = kryptonaToken.balanceOf(_member);
        require(balance > 0, string(abi.encodePacked("Insufficient Kryptona tokens", toString(balance), toAsciiString(_member))));
        members[_member] = Member(true, block.timestamp, balance * 10);
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyProposalContractOrOwner {
        require(members[_member].isMember, "Not a member");
        members[_member].isMember = false;
        emit MemberRemoved(_member);
    }

    function checkMembership(address _member) public view returns (bool) {
        return members[_member].isMember;
    }

    function getVotingPower(address _member) public view returns (uint256) {
        return members[_member].votingPower;
    }

    function contributeToTreasuryETH() public payable {
        require(msg.value > 0, "Must send ETH to contribute");
        childTreasury.depositEther();
    }

    function sendTreasuryFundsETH(
        address payable _to,
        uint256 _amount
    ) public onlyProposalContractOrOwner {
        childTreasury.withdrawEther(_to, _amount);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
