// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing ERC20 token interface and Ownable contract for access control
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DAOKryptonaTreasury.sol";

/**
 * @title DAOKryptonaChildTreasury
 * @dev Manages a child treasury for the DAOKryptona ecosystem, including interactions with the parent treasury.
 */
contract DAOKryptonaChildTreasury is Ownable {
    // State variables
    ERC20 public kryptonaToken; // Kryptona token contract instance
    DAOKryptonaTreasury public kryptonaTreasury; // Kryptona treasury contract instance

    // Events for logging treasury activities
    event EtherDeposited(address indexed depositor, uint256 amount, uint256 fee);
    event EtherWithdrawn(address indexed recipient, uint256 amount, uint256 fee);
    event FeePaidToKryptonaTreasury(uint256 fee);

    /**
     * @dev Constructor to initialize the child treasury with token and parent treasury addresses.
     * @param _kryptonaTokenAddress Address of the Kryptona token contract.
     * @param _kryptonaTreasuryAddress Address of the Kryptona treasury.
     */
    constructor(address _kryptonaTokenAddress, address payable _kryptonaTreasuryAddress) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
        kryptonaTreasury = DAOKryptonaTreasury(_kryptonaTreasuryAddress);
    }

    // Fallback function to allow the contract to receive ETH directly
    receive() external payable {
        depositEther();
    }

    /**
     * @dev Handles ETH deposits into the child treasury, applying a 1% fee that is sent to the Kryptona treasury.
     */
    function depositEther() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        uint256 fee = msg.value / 100; // Calculate a 1% fee
        uint256 amountAfterFee = msg.value - fee;

        // Attempt to send the fee to the Kryptona treasury
        (bool feeSent, ) = address(kryptonaTreasury).call{value: fee}("");
        require(feeSent, "Failed to send fee to Kryptona treasury");

        // Emit events for the deposit and fee payment
        emit FeePaidToKryptonaTreasury(fee);
        emit EtherDeposited(msg.sender, amountAfterFee, fee);
    }

    /**
     * @dev Allows the owner to withdraw ETH, applying a 1% fee that is sent to the Kryptona treasury.
     * @param recipient The address to receive the ETH.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawEther(address payable recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        uint256 fee = amount / 100; // Calculate a 1% fee
        uint256 amountAfterFee = amount - fee;
        uint256 balance = getETHBalance();
        require(balance >= amount, "Insufficient balance to withdraw");

        // Attempt to send the fee to the parent treasury
        (bool feeSent, ) = address(kryptonaTreasury).call{value: fee}("");
        require(feeSent, "Failed to send fee to Kryptona treasury");

        // Attempt to send the remaining amount after the fee to the recipient
        (bool sent, ) = recipient.call{value: amountAfterFee}("");
        require(sent, "Failed to send Ether");

        // Emit events for the withdrawal and fee payment
        emit FeePaidToKryptonaTreasury(fee);
        emit EtherWithdrawn(recipient, amountAfterFee, fee);
    }

    /**
     * @dev Retrieves the contract's current ETH balance.
     * @return The balance of ETH held by this contract.
     */
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves the balance of Kryptona tokens held by the contract.
     * @return The balance of Kryptona tokens held.
     */
    function getKryptonaTokenBalance() public view returns (uint256) {
        return kryptonaToken.balanceOf(address(this));
    }

    /**
     * @dev Converts a uint256 value to its string representation. Used for error messages.
     * @param value The value to convert.
     * @return The string representation of the value.
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
}
