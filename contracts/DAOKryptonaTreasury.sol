// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAOKryptonaTreasury is Ownable {
    ERC20 public kryptonaToken;

    constructor(address _kryptonaTokenAddress) Ownable(msg.sender) {
        kryptonaToken = ERC20(_kryptonaTokenAddress);
    }

    receive() external payable {}

    function depositETH() public payable {}

    function depositKryptonaTokens(uint256 _amount) public {
        require(kryptonaToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    }

    function sendETH(address payable _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, string(abi.encodePacked("Insufficient ETH balance: ", toString(address(this).balance), " wei available")));
        _to.transfer(_amount);
    }

    function sendKryptonaTokens(address _to, uint256 _amount) public onlyOwner {
        uint256 currentBalance = kryptonaToken.balanceOf(address(this));
        require(currentBalance >= _amount, string(abi.encodePacked("Insufficient Kryptona token balance: ", toString(currentBalance), " tokens available")));
        require(kryptonaToken.transfer(_to, _amount), "Token transfer failed");
    }

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getKryptonaTokenBalance() public view returns (uint256) {
        return kryptonaToken.balanceOf(address(this));
    }

    // Utility function to convert a uint256 value to a string
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
