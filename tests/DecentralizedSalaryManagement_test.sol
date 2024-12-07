// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "remix_accounts.sol";
import "hardhat/console.sol";
import "../contracts/project/DecentralizedSalaryManagement.sol";

contract DecentralizedSalaryManagementTest is DecentralizedSalaryManagement {

    /// #sender: account-0
    // Constructor to initialize the contract with initial balance
    constructor() {
        // Call the super constructor with the message sender address
        // Sets the initial owner to account-0
        super;
    }
    
    /// #sender: account-0
    /// #value: 10 wei
    // Test replenishing the contract balance by the owner
    function testReplenish() public payable {
        // Should work as owner is the sender
        super.replenish();
        // Check if balance updated correctly and Replenished event emitted
        Assert.equal(getBalance(), 10 wei, "Balance should be replenished by 10 wei");
    }

    /// #sender: account-0
    // Test registering a new employee
    function testRegisterEmployee() public {
        address employeeAddress = TestsAccounts.getAccount(1);
        uint256 salary = 1 wei;
       
        // Register a new employee
        register(employeeAddress, salary);
       
        // Verify employee registration
        Employee memory emp = employees[employeeAddress];
        Assert.equal(emp.salary, salary, "Employee salary should be set correctly");
        Assert.equal(emp.isActive, true, "Employee should be marked as active");
    }

    /// #sender: account-1
    /// #value: 1 wei
    // Test withdrawing salary by an active employee
    function testWithdrawSalary() public {
        address employeeAddress = TestsAccounts.getAccount(1);
        uint256 initialBalance = employeeAddress.balance;
       
        // Attempt to withdraw salary
        withdrawAmount();

        // Check if the event was emitted correctly and salary transferred
        Assert.ok(employeeAddress.balance - initialBalance == 1 wei, "Amount withdrawn should be greater than zero");
    }

    /// #sender: account-1
    /// #value: 1 wei
    // employee cannot withdraw twice in one month
    function testWithDrawSalaryTwiceInOneMonth() public {
        // Attempt to withdraw salary
        (bool r,) = address(this).call(abi.encodeWithSignature("withdrawAmount()"));

        Assert.ok(!r, "employee cannot withdraw twice in one month");
    }

    /// #sender: account-1
    // Test submitting an idea
    function testSubmitIdea() public {
        string memory ideaDescription = "A new project idea";
        address ideaSubmitter = TestsAccounts.getAccount(1);
       
        // Check that ideas array is empty initially
        Assert.equal(ideas.length, 0, "Ideas array should be empty initially");
       
        // Submit an idea
        submitIdea(ideaSubmitter, ideaDescription);
       
        // Verify idea submission
        Assert.equal(ideas.length, 1, "Idea should be added to the array");
        Idea memory idea = ideas[0];
        Assert.equal(idea.submitter, ideaSubmitter, "Submitter address should match");
        Assert.equal(idea.description, ideaDescription, "Idea description should match");
    }

    /// #sender: account-0
    // Test idea approval by the owner
    function testApprovalIdea() public {
        uint256 bonus = 1 wei;
        uint256 ideaIndex = 0;
       
        address submitter = TestsAccounts.getAccount(1);
        uint256 initialBalance = submitter.balance;
        // Approve the idea with given index
        approvalIdea(ideaIndex, bonus);
       
        // Verify that the bonus is assigned
        Idea memory idea = ideas[ideaIndex];
        Assert.equal(idea.bonus, bonus, "Bonus should be set correctly for the idea");
        Assert.equal(bonus, submitter.balance - initialBalance, "submitter can get bonus when idea was approvalled");
    }

    // test get idea history
    function testGetIdeaHistory() public {
        (address[] memory submitters,, uint256[] memory bonuses) = getIdeaHistory();
        Assert.equal(submitters[0], TestsAccounts.getAccount(1), "submitter should be account 1");
        Assert.equal(bonuses[0], 1, "bonus should be 1 wei");
    }
}