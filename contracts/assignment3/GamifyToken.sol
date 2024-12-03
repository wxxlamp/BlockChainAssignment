// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GamifyToken is ERC20, Ownable {
    uint256 public taxRate; // Transaction tax rate in %
    uint256 public burnRate; // Burn rate in %
    uint256 public rewardRate; // Reward rate for holders in %
    mapping(address => uint256) public lastClaimed; // Track last claim time for rewards

    address[] private holders; // Array to store token holders
    mapping(address => bool) private isHolder; // Mapping to check if an address is a holder

    constructor() ERC20("GamifyToken", "GAM") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Initial supply of 1 million tokens
        taxRate = 2; // Default 2% tax
        burnRate = 1; // Default 1% burn
        rewardRate = 5; // Default 5% annual reward
        // Add the contract deployer as the first holder
        _addHolder(msg.sender);
    }
 
    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal  {
        uint256 tax = (amount * taxRate) / 100;
        uint256 burn = (amount * burnRate) / 100;
        uint256 netAmount = amount - tax - burn;

        // Distribute tax to all token holders
        _distributeTax(tax);

        // Burn the calculated amount
        _burn(sender, burn);

        // Perform the actual transfer
        super._transfer(sender, recipient, netAmount);

        // Add recipient as a token holder if they have a balance greater than zero
        if (balanceOf(recipient) > 0) {
            _addHolder(recipient);
        }

        // Remove sender from holders if their balance becomes zero
        if (balanceOf(sender) == 0) {
            _removeHolder(sender);
        }
    }

    function _distributeTax(uint256 tax) private {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) return;

        // Distribute tax as rewards to all token holders
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 reward = (balanceOf(holder) * tax) / totalSupply_;
            _mint(holder, reward);
        }
    }

    function claimRewards() external {
        uint256 timeHeld = block.timestamp - lastClaimed[msg.sender];
        uint256 reward = (balanceOf(msg.sender) * rewardRate * timeHeld) / (365 days * 100);
        require(reward > 0, "No rewards available");
        
        _mint(msg.sender, reward);
        lastClaimed[msg.sender] = block.timestamp;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 10, "Tax rate cannot exceed 10%");
        taxRate = _taxRate;
    }

    function setBurnRate(uint256 _burnRate) external onlyOwner {
        require(_burnRate <= 5, "Burn rate cannot exceed 5%");
        burnRate = _burnRate;
    }

    // Function to get all holders
    function getHolders() external view returns (address[] memory) {
        return holders;
    }

    // Internal function to add a holder
    function _addHolder(address account) internal {
        if (!isHolder[account]) {
            isHolder[account] = true;
            holders.push(account);
        }
    }

    // Internal function to remove a holder
    function _removeHolder(address account) internal {
        if (isHolder[account]) {
            isHolder[account] = false;

            // Find and remove the account from the holders array
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == account) {
                    holders[i] = holders[holders.length - 1]; // Replace with last element
                    holders.pop(); // Remove the last element
                    break;
                }
            }
        }
    }
}