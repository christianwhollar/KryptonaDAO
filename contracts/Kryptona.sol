// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for ERC20 token functionality, capping, burnability, and ownership
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Kryptona
 * @dev Extends ERC20 token standard with capping, burnability, and ownership for the Kryptona token.
 * It includes mechanisms for minting tokens, setting block rewards, and updating token state.
 */
contract Kryptona is ERC20, ERC20Capped, ERC20Burnable, Ownable {
    // State variable for the block reward
    uint256 public blockReward;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens and sets up the token.
     * @param cap Maximum supply of the token.
     * @param initialSupply Initial supply of tokens to mint upon deployment.
     * @param reward Initial block reward for miners.
     */
    constructor(
        uint256 cap,
        uint256 initialSupply,
        uint256 reward
    )
        ERC20("Kryptona", "KRYPTONA") // Name and symbol for the token
        ERC20Capped(cap * (10 ** decimals())) // Initialize capping with the cap value adjusted for decimals
        Ownable(msg.sender) // Set the contract deployer as the initial owner
    {
        // Mint initial supply to the deployer and set the block reward, both adjusted for decimals
        _mint(msg.sender, initialSupply * (10 ** decimals()));
        blockReward = reward * (10 ** decimals());
    }

    /**
     * @dev Overrides the _update function from ERC20 and ERC20Capped to ensure compatibility.
     * @param from Address tokens are moving from.
     * @param to Address tokens are moving to.
     * @param amount Number of tokens.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        super._update(from, to, amount);
    }

    /**
     * @dev Public function to mint tokens, restricted to contract owner.
     * @param to Address to receive the minted tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Internal function to mint block rewards to the miner of the current block.
     */
    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    /**
     * @dev Allows the contract owner to set the block reward.
     * @param reward New block reward to be set.
     */
    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * (10 ** decimals());
    }
}
