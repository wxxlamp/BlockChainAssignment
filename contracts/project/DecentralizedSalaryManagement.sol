// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedSalaryManagement is Ownable, ReentrancyGuard {

    // Employee struct to store individual employee details
    struct Employee {
        uint256 salary; // Monthly salary in wei
        uint256 lastWithdrawTime; // Last time the salary was withdrawn
        uint256 startTime; // Start time of employment (in block number)
        bool isActive; // Employment status
    }

    // Idea struct to store details about submitted ideas
    struct Idea {
        address submitter;
        string description; // Description of the idea
        uint256 bonus; // Bonus amount for the idea
    }

    mapping(address => Employee) public employees;
    Idea[] public ideas;

    uint256 public lastReplenishBlock;
    // Approx. 6 months in blocks (assuming 15s average block time)
    uint256 public constant REPLENISH_INTERVAL_BLOCKS = 1296000; 
    // Approx. blocks in a year (assuming 15s average block time)
    uint256 private constant PER_YEAR_INTERVAL_BLOCKS = 210240000;
    // Approx. number of blocks in a month (assuming 15s block time)
    uint256 private constant PER_MONTH_INTERVAL_BLOCKS = 172800; 


    // Events
    event Replenished(uint256 amount);
    event EmployeeRegistered(address indexed employee, uint256 salary);
    event SalaryWithdrawn(address indexed employee, uint256 amount);
    event IdeaSubmitted(address indexed employee, address ideaAddress, string description);
    event IdeaApproved(address indexed ideaAddress, uint256 bonus);

    constructor() Ownable(msg.sender) {}

    // Function to replenish Ether to the contract, only callable by the owner
    function replenish() public payable onlyOwner {
        require(
            lastReplenishBlock == 0 || block.number >= lastReplenishBlock + REPLENISH_INTERVAL_BLOCKS,
            "Replenish only allowed after interval"
        );
        lastReplenishBlock = block.number;
        emit Replenished(msg.value);
    }

    // Function to register a new employee, only callable by the owner
    function register(address employee, uint256 salary) public onlyOwner {
        require(employee != address(0), "Invalid employee address");
        require(salary > 0, "Salary must be greater than zero");
        require(!employees[employee].isActive, "Employee already registered");

        employees[employee] = Employee(salary, 0, block.number, true);
        emit EmployeeRegistered(employee, salary);
    }

    // Function for employees to withdraw their salary
    function withdrawAmount() public nonReentrant returns (uint256) {
        Employee storage employee = employees[msg.sender];
        require(employee.isActive, "Employee is not active");
        require(employee.lastWithdrawTime == 0 || block.number >= employee.lastWithdrawTime + PER_MONTH_INTERVAL_BLOCKS, "Withdrawal allowed once per month");
        require(address(this).balance >= employee.salary, "Insufficient contract balance");

        uint256 blocksElapsed = block.number - employee.startTime;

        // Calculate the updated salary
        uint updatedSalary = employee.salary + employee.salary * 5 * blocksElapsed / PER_YEAR_INTERVAL_BLOCKS;  
        // Update state before external call
        employee.lastWithdrawTime = block.number;

        emit SalaryWithdrawn(msg.sender, updatedSalary);

        payable(msg.sender).transfer(updatedSalary);
        return updatedSalary;
    }

    // Function for employees to submit ideas
    function submitIdea(address submitter, string memory ideaDescription) public {
        require(employees[msg.sender].isActive, "Only active employees can submit ideas");
        require(submitter != address(0), "Invalid idea address");

        ideas.push(Idea(submitter, ideaDescription, 0));
        emit IdeaSubmitted(msg.sender, submitter, ideaDescription);
    }

    // Function for the owner to approve an idea and assign a bonus
    function approvalIdea(uint256 index, uint256 bonus) public nonReentrant onlyOwner {
        require(index < ideas.length, "Idea does not exist");
        require(ideas[index].bonus == 0, "Idea already approved");
        require(bonus > 0, "Bonus must be greater than zero");
        require(address(this).balance >= bonus, "Insufficient contract balance");

        // Update state before external call
        ideas[index].bonus = bonus;

        emit IdeaApproved(ideas[index].submitter, bonus);
        payable(ideas[index].submitter).transfer(bonus);
    }

    function getIdeaHistory() public view returns(address[] memory, string[] memory, uint256[] memory) {
        uint256 ideaCount = ideas.length; 

        address[] memory submitters = new address[](ideaCount);
        string[] memory descriptions = new string[](ideaCount);
        uint256[] memory bonuses = new uint256[](ideaCount);
        
        for (uint256 i = 0; i < ideaCount; i++) {
            Idea storage idea = ideas[i];
            submitters[i] = idea.submitter;
            descriptions[i] = idea.description;
            bonuses[i] = idea.bonus;
        }

        return (submitters, descriptions, bonuses);
    }

    // Function to get the contract's balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}