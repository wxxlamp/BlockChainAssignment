// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedSalaryManagement is Ownable, ReentrancyGuard {

    // Employee struct to store individual employee details
    struct Employee {
        uint256 salary; // Monthly salary in wei
        uint256 lastWithdrawTime; // Last time the salary was withdrawn
        uint256 startTime; // Start time of employment
        bool isActive; // Employment status
    }

    // Idea struct to store details about submitted ideas
    struct Idea {
        address submitter;
        string description; // Description of the idea
        uint256 bonus; // Bonus amount for the idea
    }

    // Mapping from employee address to their details
    mapping(address => Employee) public employees;
    // Mapping from idea address to idea details
    Idea[] public ideas;

    // State variable to store the last time Ether was replenished in the contract
    uint256 public lastReplenishTime;
    // Constant for the replenish interval (180 days)
    uint256 public constant REPLENISH_INTERVAL = 180 days;

    // Events
    event Replenished(uint256 amount);
    event EmployeeRegistered(address indexed employee, uint256 salary);
    event SalaryWithdrawn(address indexed employee, uint256 amount);
    event IdeaSubmitted(address indexed employee, address ideaAddress, string description);
    event IdeaApproved(address indexed ideaAddress, uint256 bonus);

    constructor() Ownable(msg.sender) {}

    // Function to replenish Ether to the contract, only callable by the owner
    function replenish() external payable onlyOwner {
        require(block.timestamp >= lastReplenishTime + REPLENISH_INTERVAL, "Replenish only allowed after interval");
        lastReplenishTime = block.timestamp;
        emit Replenished(msg.value);
    }

    // Function to register a new employee, only callable by the owner
    function register(address employee, uint256 salary) external onlyOwner {
        require(employee != address(0), "Invalid employee address");
        require(salary > 0, "Salary must be greater than zero");
        require(!employees[employee].isActive, "Employee already registered");

        employees[employee] = Employee(salary, block.timestamp, block.timestamp, true);
        emit EmployeeRegistered(employee, salary);
    }

    // Function for employees to withdraw their salary
    function withdrawAmount() external nonReentrant returns (uint256) {
        Employee storage employee = employees[msg.sender];
        require(employee.isActive, "Employee is not active");
        require(address(this).balance >= employee.salary, "Insufficient contract balance");

        uint256 yearsElapsed = (block.timestamp - employee.startTime) / 365 days;
        uint256 updatedSalary = employee.salary * (100 + 5 * yearsElapsed) / 100;

        employee.lastWithdrawTime = block.timestamp;
        payable(msg.sender).transfer(updatedSalary);
        emit SalaryWithdrawn(msg.sender, updatedSalary);

        return updatedSalary;
    }

    // Function for employees to submit ideas
    function submitIdea(address submitter, string memory ideaDescription) external {
        require(employees[msg.sender].isActive, "Only active employees can submit ideas");
        require(submitter != address(0), "Invalid idea address");

        ideas.push(Idea(submitter, ideaDescription, 0));
        emit IdeaSubmitted(msg.sender, submitter, ideaDescription);
    }

    // Function for the owner to approve an idea and assign a bonus
    function approvalIdea(uint index, uint256 bonus) external nonReentrant onlyOwner {
        require(index < ideas.length, "Idea is not exist");
        require(ideas[index].bonus == 0, "Idea already approved");
        require(bonus > 0, "Bonus must be greater than zero");
        require(address(this).balance >= bonus, "Insufficient contract balance");

        ideas[index].bonus = bonus;
        payable(ideas[index].submitter).transfer(bonus);
        emit IdeaApproved(ideas[index].submitter, bonus);
    }

    // Function to get the contract's balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}