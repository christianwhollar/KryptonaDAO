// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing ERC20 token interface and Ownable contract for access control from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DAOKryptonaTreasury
 * @dev Manages the treasury for the DAOKryptona ecosystem, including ETH and Kryptona tokens.
 */
contract DAOKryptonaTreasury is Ownable {
    // Public state variable to hold the ERC20 Kryptona token contract instance
    ERC20 public kryptonaToken;

    /**
     * @dev Constructor initializes the treasury with the Kryptona token contract address.
     * @param _kryptonaTokenAddress Address of the Kryptona token contract.
     */
    constructor(address _kryptonaTokenAddress) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
    }

    // Fallback function to allow the treasury to receive ETH directly without calling a function.
    receive() external payable {}

    /**
     * @dev Allows depositing ETH into the treasury without the need for data (fallback).
     */
    function depositETH() public payable {}

    /**
     * @dev Allows depositing Kryptona tokens into the treasury.
     * @param _amount The amount of Kryptona tokens to deposit.
     */
    function depositKryptonaTokens(uint256 _amount) public {
        require(kryptonaToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    }

    /**
     * @dev Sends ETH from the treasury to a specified address.
     * @param _to Recipient address of the ETH.
     * @param _amount Amount of ETH to send.
     */
    function sendETH(address payable _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, string(abi.encodePacked("Insufficient ETH balance: ", toString(address(this).balance), " wei available")));
        _to.transfer(_amount);
    }

    /**
     * @dev Sends Kryptona tokens from the treasury to a specified address.
     * @param _to Recipient address of the tokens.
     * @param _amount Amount of Kryptona tokens to send.
     */
    function sendKryptonaTokens(address _to, uint256 _amount) public onlyOwner {
        uint256 currentBalance = kryptonaToken.balanceOf(address(this));
        require(currentBalance >= _amount, string(abi.encodePacked("Insufficient Kryptona token balance: ", toString(currentBalance), " tokens available")));
        require(kryptonaToken.transfer(_to, _amount), "Token transfer failed");
    }

    /**
     * @dev Retrieves the treasury's current ETH balance.
     * @return The balance of ETH in the treasury.
     */
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves the treasury's current Kryptona token balance.
     * @return The balance of Kryptona tokens in the treasury.
     */
    function getKryptonaTokenBalance() public view returns (uint256) {
        return kryptonaToken.balanceOf(address(this));
    }

    /**
     * @dev Internal utility function to convert a uint256 value to its string representation.
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
