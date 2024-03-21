// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KryptonaTreasury.sol";

contract TreasuryChild is Ownable {
    ERC20 public kryptonaToken;

    // The parent treasury to interact with
    KryptonaTreasury public parentTreasury;

    // Event declarations for logging activities
    event EtherDeposited(
        address indexed depositor,
        uint256 amount,
        uint256 fee
    );
    event EtherWithdrawn(
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );
    event FeePaidToParentTreasury(uint256 fee);

    constructor(
        address _kryptonaTokenAddress,
        address payable _parentTreasuryAddress
    ) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
        parentTreasury = KryptonaTreasury(_parentTreasuryAddress);
    }

    // Fallback function to accept ETH deposits directly
    receive() external payable {
        depositEther();
    }

    // Function to handle ETH deposits, including the 1% fee to the parent treasury
    function depositEther() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        uint256 fee = msg.value / 100; // 1% fee
        uint256 amountAfterFee = msg.value - fee;

        // Send the fee to the parent treasury
        (bool feeSent, ) = address(parentTreasury).call{value: fee}("");
        require(feeSent, "Failed to send fee to parent treasury");

        emit FeePaidToParentTreasury(fee);
        emit EtherDeposited(msg.sender, amountAfterFee, fee);
    }

    // Function allowing the owner to withdraw ETH, including a 1% fee sent to the parent treasury
    function withdrawEther(
        address payable recipient,
        uint256 amount
    ) public onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        uint256 fee = amount / 100; // 1% fee
        uint256 amountAfterFee = amount - fee;

        require(
            address(this).balance >= amount,
            "Insufficient balance to withdraw"
        );

        // Send the fee to the parent treasury
        (bool feeSent, ) = address(parentTreasury).call{value: fee}("");
        require(feeSent, "Failed to send fee to parent treasury");

        // Send the remaining amount after the fee to the recipient
        (bool sent, ) = recipient.call{value: amountAfterFee}("");
        require(sent, "Failed to send Ether");

        emit FeePaidToParentTreasury(fee);
        emit EtherWithdrawn(recipient, amountAfterFee, fee);
    }

    // Utility function to check the contract's ETH balance
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getKryptonaTokenBalance() public view returns (uint256) {
        return kryptonaToken.balanceOf(address(this));
    }
}
