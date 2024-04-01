// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's ERC20 standard token implementation and Ownable contract for access control
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing the DAOKryptonaTreasury contract
import "./DAOKryptonaTreasury.sol";

/**
 * @title DAOKryptona
 * @dev Implementation of a DAO managing members and their interactions with a treasury.
 */
contract DAOKryptona is Ownable {
    // State variables
    ERC20 public kryptonaToken; // Token used for DAO operations
    DAOKryptonaTreasury public kryptonaTreasury; // The DAO's treasury
    address public proposalContract; // Contract managing proposals

    // Member structure to store member data
    struct Member {
        bool isMember;       // Whether the address is a DAO member
        uint256 joinedAt;    // Timestamp of joining
        uint256 votingPower; // Voting power based on token holdings
    }

    // Mapping of addresses to member data
    mapping(address => Member) public members;

    // Events
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event TreasuryFunded(uint256 amount);

    /**
     * @dev Constructor setting up the DAO.
     * @param _kryptonaTokenAddress Address of the Kryptona token.
     * @param _kryptonaTreasuryAddress Address of the Kryptona treasury contract.
     */
    constructor(
        address _kryptonaTokenAddress,
        address _kryptonaTreasuryAddress
    ) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
        kryptonaTreasury = new DAOKryptonaTreasury(_kryptonaTreasuryAddress);
    }

    /**
     * @dev Sets the proposal contract address.
     * @param _proposalContract The address of the proposal contract.
     */
    function setProposalContract(address _proposalContract) public onlyOwner {
        proposalContract = _proposalContract;
    }

    // Modifier to restrict function calls to the proposal contract or the owner
    modifier onlyProposalContractOrOwner() {
        require(
            msg.sender == proposalContract || msg.sender == owner(),
            "Callable only by proposal contract or owner"
        );
        _;
    }

    /**
     * @dev Adds a member to the DAO.
     * @param _member Address of the member to be added.
     */
    function addMember(address _member) public onlyProposalContractOrOwner {
        require(!members[_member].isMember, "Member already exists");
        uint256 balance = kryptonaToken.balanceOf(_member);
        require(
            balance > 0,
            string(
                abi.encodePacked(
                    "Insufficient Kryptona tokens ",
                    toString(balance),
                    toAsciiString(_member)
                )
            )
        );
        members[_member] = Member(true, block.timestamp, balance * 10);
        emit MemberAdded(_member);
    }

    /**
     * @dev Removes a member from the DAO.
     * @param _member Address of the member to be removed.
     */
    function removeMember(address _member) public onlyProposalContractOrOwner {
        require(members[_member].isMember, "Not a member");
        members[_member].isMember = false;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Checks if an address is a member of the DAO.
     * @param _member Address to check.
     * @return bool Whether the address is a DAO member.
     */
    function checkMembership(address _member) public view returns (bool) {
        return members[_member].isMember;
    }

    /**
     * @dev Retrieves the voting power of a member.
     * @param _member Address of the member.
     * @return uint256 Voting power of the member.
     */
    function getVotingPower(address _member) public view returns (uint256) {
        return members[_member].votingPower;
    }

    /**
     * @dev Allows contributing ETH to the treasury.
     */
    function contributeToTreasuryETH() public payable {
        require(msg.value > 0, "Must send ETH to contribute");
        (bool sent, ) = address(kryptonaTreasury).call{value: msg.value}("");
        require(sent, "Failed to send ETH to treasury");
    }

    /**
     * @dev Allows contributing Kryptona tokens to the treasury.
     * @param _amount Amount of Kryptona tokens to contribute.
     */
    function contributeToTreasuryKryptonaTokens(uint256 _amount) public {
        require(
            kryptonaToken.transferFrom(msg.sender, address(kryptonaTreasury), _amount),
            "Token transfer failed"
        );
    }

    /**
     * @dev Sends ETH from the treasury to a specified address.
     * @param _to Recipient address.
     * @param _amount Amount of ETH to send.
     */
    function sendTreasuryFundsETH(
        address payable _to,
        uint256 _amount
    ) public onlyProposalContractOrOwner {
        kryptonaTreasury.sendETH(_to, _amount);
    }

    /**
     * @dev Sends Kryptona tokens from the treasury to a specified address.
     * @param _to Recipient address.
     * @param _amount Amount of Kryptona tokens to send.
     */
    function sendTreasuryFundsKryptonaTokens(
        address payable _to,
        uint256 _amount
    ) public onlyProposalContractOrOwner {
        kryptonaTreasury.sendKryptonaTokens(_to, _amount);
    }

    // Utility functions for internal use

    /**
     * @dev Converts a uint256 to a string.
     * @param value The value to convert.
     * @return string The string representation of the value.
     */
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

    /**
     * @dev Converts an address to an ASCII string.
     * @param x The address to convert.
     * @return string The ASCII string representation of the address.
     */
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

    /**
     * @dev Converts a byte to a character.
     * @param b The byte to convert.
     * @return c The character representation of the byte.
     */
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
