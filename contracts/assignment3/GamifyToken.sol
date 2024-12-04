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
    mapping(address => uint256) public voteTaxRate;
    mapping(address => uint256) public voteBurnRate;


    event TaxRateChanged(uint256 newTaxRate);
    event BurnRateChanged(uint256 newBurnRate);

   constructor() ERC20("GamifyToken", "GAM") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Initial supply of 1 million tokens
        taxRate = 2; // Default 2% tax
        burnRate = 1; // Default 1% burn
        rewardRate = 5; // Default 5% annual reward
        // Add the contract deployer as the first holder
        _addHolder(msg.sender);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 tax = (amount * taxRate) / 100;
        uint256 burn = (amount * burnRate) / 100;
        uint256 netAmount = amount - tax - burn;

        // Distribute tax to all token holders
        _distributeTax(tax);

        // Burn the calculated amount
        _burn(_msgSender(), burn);

        // Perform the actual transfer
        super.transfer(recipient, netAmount);

        _updateHolders(_msgSender(), recipient);

        return true;
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

    function updateTaxRate() external onlyOwner {

        uint sumTaxRate = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            sumTaxRate += voteTaxRate[holder];
        }
        taxRate = sumTaxRate/holders.length;
        emit TaxRateChanged(taxRate);
    }

    function updateBurnRate() external onlyOwner {
        uint sumBurnRate = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            sumBurnRate += voteBurnRate[holder];
        }
        burnRate = sumBurnRate/holders.length;
        emit BurnRateChanged(burnRate);
    }

    function voteOnTaxRate(uint256 _proposedTaxRate) external {
        require(_proposedTaxRate > 0, "_proposedTaxRate must larger than 0");
        require(_proposedTaxRate <= 10, "Tax rate cannot exceed 10%");
        require(balanceOf(msg.sender) > 0, "Only token holders can vote");
        voteTaxRate[msg.sender] = _proposedTaxRate;
    }

    function voteOnBurnRate(uint256 _proposedBurnRate) external {
        require(balanceOf(msg.sender) > 0, "Only token holders can vote");
        require(_proposedBurnRate > 0, "_proposedBurnRate must larger than 0");
        require(_proposedBurnRate <= 5, "Burn rate cannot exceed 5%");

        voteBurnRate[msg.sender] = _proposedBurnRate;
    }

    function _updateHolders(address sender, address recipient) private {
        if (balanceOf(recipient) > 0 && !isHolder[recipient]) {
            _addHolder(recipient);
        }
        if (balanceOf(sender) == 0) {
            _removeHolder(sender);
        }
    }

    // Internal function to add a holder
    function _addHolder(address account) private {
        if (!isHolder[account]) {
            isHolder[account] = true;
            holders.push(account);
        }
    }

    // Internal function to remove a holder

    function _removeHolder(address account) private {
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