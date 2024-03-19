// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Treasury {
    address public owner;
    address payable public kryptonaTreasuryAddress;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    constructor(address payable _kryptonaTreasuryAddress) {
        owner = msg.sender;
        kryptonaTreasuryAddress = _kryptonaTreasuryAddress;
    }

    // Allow the contract to receive Ether
    receive() external payable {
        uint256 fee = msg.value / 100;
        kryptonaTreasuryAddress.transfer(fee);
    }

    function withdraw(address payable to, uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

}
