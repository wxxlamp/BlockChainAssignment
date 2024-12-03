// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_accounts.sol";
import "remix_tests.sol"; 
import "hardhat/console.sol";
import "../contracts/assignment2/RentalAgreementManagement.sol";

contract RentalAgreementManagementTest is RentalAgreementManagement {
    address landlord = TestsAccounts.getAccount(0);
    address tenant1 = TestsAccounts.getAccount(1);
    address tenant2 = TestsAccounts.getAccount(2);

    function beforeEach() public {
        // Reset the contract state before each test
        // No need to initialize again since we are inheriting from the RentalAgreementManagement
    }

    /// #sender: account-0
    function testCreateAgreement() public {
        createAgreement(tenant1, 1 ether, 30 days);
        Agreement storage agreement = agreements[1];
        address createdTenant = agreement.tenant;
        uint256 rentAmount = agreement.rentAmount;
        uint256 duration = agreement.duration;

        Assert.equal(createdTenant, tenant1, "Tenant should be tenant1");
        Assert.equal(rentAmount, 1 ether, "Rent amount should be 1 ether");
        Assert.equal(duration, 30 days, "Duration should be 30 days");

        // prepare addtional agreements for test
        createAgreement(tenant1, 1 ether, 30 days);
        createAgreement(tenant1, 1 ether, 30 days);
    }

    /// #sender: account-1
    /// #value: 1000000000000000000 // 1 Ether
    function testPayRent() public payable {
        uint initValue = landlord.balance;
        payRent(1);

        uint256 paymentCount = agreements[1].paymentCount;
        Assert.equal(paymentCount, 1, "Payment count should be 1 after first payment");
        Assert.equal(landlord.balance, initValue + 1 ether, "lanlord's balance should add 1 ether after payment");
        Assert.equal(block.timestamp, paymentHistory[1][1], "Payment history should include current time");
    }

    /// #sender: account-1
    /// #value: 1000000000000000000 // 1 Ether
    function testPayRentMultipleTimes() public payable {
        payRent(1);

        uint256 paymentCount = agreements[1].paymentCount;
        Assert.equal(paymentCount, 2, "Payment count should be 2 after second payment");
        Assert.equal(block.timestamp, paymentHistory[1][2], "Payment history should include current time");
    }

    /// #sender: account-0
    function testTerminateAgreement() public {
        terminateAgreement(1);

        string memory status = getAgreementStatus(1);
        Assert.equal(status, "Terminated", "Agreement should be terminated");
    }

    /// #sender: account-1
    function testTerminateAgreementByNonLandlord() public {
        bool r;
        (r, ) = address(this).call(abi.encodeWithSignature("terminateAgreement(uint256)", 2));
        Assert.ok(!r, "Only landlord should be able to terminate the agreement");
    }

    /// #sender: account-1
    /// #value: 1
    function testPayRentWrongAmount() public payable {

        // Attempt to pay rent with incorrect amount
        bool r;
        (r, ) = address(this).call{value: 1 wei}(abi.encodeWithSignature("payRent(uint256)", 3));
        Assert.ok(!r, "Should not allow payment with incorrect rent amount");
    }

    /// #sender: account-0
    function testGetAgreementStatus() public {
        createAgreement(tenant1, 1 ether, 30 days);
        string memory status = getAgreementStatus(2);
        Assert.equal(status, "Active", "Agreement should be active after creation");
        string memory terminatedStatus = getAgreementStatus(1);
        Assert.equal(terminatedStatus, "Terminated", "Agreement should be active after creation");
    }
}