// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing ERC20 standard and Ownable contract for token interaction and access control
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing other components of the DAOKryptona ecosystem
import "./DAOKryptonaTreasury.sol";
import "./DAOKryptonaChildTreasury.sol";
import "./Model.sol";

/**
 * @title DAOKryptonaChild
 * @dev Extends the DAOKryptona DAO with additional features and child treasury management.
 */
contract DAOKryptonaChild is Ownable {

    // Public state variables
    ERC20 public kryptonaToken; // Kryptona token contract instance
    DAOKryptonaTreasury public kryptonaTreasury; // Main treasury for the DAO
    DAOKryptonaChildTreasury public kryptonaChildTreasury; // Child treasury specific to this contract
    AIModel public model; // AI model for DAO interactions
    string private tokenURI; // URI for token metadata
    address public proposalContract; // Contract managing DAO proposals
    
    // Member structure for DAO membership
    struct Member {
        bool isMember; // Boolean flag for membership status
        uint256 joinedAt; // Timestamp of membership initiation
        uint256 votingPower; // Voting power assigned to the member
    }

    // Mapping from addresses to their membership status
    mapping(address => Member) public members;

    // Events for tracking contract activities
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event TreasuryFunded(uint256 amount);
    event ModelAdded();
    event ModelUpdated();

    /**
     * @dev Constructor to initialize contract with token and treasury addresses.
     * @param _kryptonaTokenAddress Address of the Kryptona token contract.
     * @param _kryptonaTreasuryAddress Address for the main treasury contract.
     */
    constructor(address _kryptonaTokenAddress, address payable _kryptonaTreasuryAddress) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
        kryptonaTreasury = new DAOKryptonaTreasury(_kryptonaTreasuryAddress);
        kryptonaChildTreasury = new DAOKryptonaChildTreasury(_kryptonaTokenAddress, _kryptonaTreasuryAddress);
    }

    /**
     * @dev Sets the proposal contract address.
     * @param _proposalContract Address of the proposal management contract.
     */
    function setProposalContract(address _proposalContract) public onlyOwner {
        proposalContract = _proposalContract;
    }

    // Modifier to restrict certain functions to the proposal contract or the owner
    modifier onlyProposalContractOrOwner() {
        require(msg.sender == proposalContract || msg.sender == owner(), "Callable only by proposal contract or owner");
        _;
    }

    /**
     * @dev Adds a new member to the DAO.
     * @param _member Address of the new member.
     */
    function addMember(address _member) public onlyProposalContractOrOwner {
        require(!members[_member].isMember, "Member already exists");
        uint256 balance = kryptonaToken.balanceOf(_member);
        require(balance > 0, string(abi.encodePacked("Insufficient Kryptona tokens", toString(balance), toAsciiString(_member))));
        members[_member] = Member(true, block.timestamp, balance * 10);
        emit MemberAdded(_member);
    }

    /**
     * @dev Removes an existing member from the DAO.
     * @param _member Address of the member to remove.
     */
    function removeMember(address _member) public onlyProposalContractOrOwner {
        require(members[_member].isMember, "Not a member");
        members[_member].isMember = false;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Checks if an address is a DAO member.
     * @param _member Address to check.
     * @return bool Membership status.
     */
    function checkMembership(address _member) public view returns (bool) {
        return members[_member].isMember;
    }

    /**
     * @dev Retrieves the voting power of a DAO member.
     * @param _member Address of the member.
     * @return uint256 Voting power of the member.
     */
    function getVotingPower(address _member) public view returns (uint256) {
        return members[_member].votingPower;
    }

    /**
     * @dev Allows a member to contribute ETH to the child treasury.
     */
    function contributeToTreasuryETH() public payable {
        require(msg.value > 0, "Must send ETH to contribute");
        (bool sent, ) = address(kryptonaChildTreasury).call{value: msg.value}("");
        require(sent, "Failed to send ETH to treasury");
    }

    /**
     * @dev Sends ETH from the child treasury to a specified address.
     * @param _to Recipient address.
     * @param _amount Amount of ETH to send.
     */
    function sendTreasuryFundsETH(address payable _to, uint256 _amount) public onlyProposalContractOrOwner {
        kryptonaChildTreasury.withdrawEther(_to, _amount);
    }

    /**
     * @dev Retrieves the ETH balance of the child treasury.
     * @return uint256 ETH balance.
     */
    function getETHBalance() public view returns (uint256) {
        return kryptonaChildTreasury.getETHBalance();
    }

    /**
     * @dev Adds a new AI model to the DAO.
     * @param _tokenURI URI for the model's token metadata.
     */
    function addModel(string memory _tokenURI) public onlyProposalContractOrOwner {
        require(address(model) == address(0), "Model is already assigned.");
        tokenURI = _tokenURI;
        model = new AIModel();
        model.mintNFT(address(this), _tokenURI);
    }

    /**
     * @dev Updates the existing AI model's metadata URI.
     * @param _tokenURI New URI for the model's token metadata.
     */
    function updateModel(string memory _tokenURI) public onlyProposalContractOrOwner {
        require(address(model) != address(0), "Model does not exist.");
        tokenURI = _tokenURI;
        model.mintNFT(address(this), _tokenURI);
    }

    /**
     * @dev Retrieves the token URI of the current AI model.
     * @return string URI of the model's token.
     */
    function getTokenURI() external view returns (string memory) {
        return tokenURI;
    }

    // Utility functions for internal use

    /**
     * @dev Converts a uint256 value to its string representation.
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
     * @dev Converts an address to a string in ASCII.
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
     * @dev Converts a byte into a character.
     * @param b The byte to convert.
     * @return c The character representation of the byte.
     */
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
