// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_accounts.sol";
import "remix_tests.sol"; 
import "hardhat/console.sol";
import "../contracts/assignment2/DecentralizedCharityFund.sol";

contract DecentralizedCharityFundTest {
    DecentralizedCharityFund charityFund;
    address projectOwner = address(0x123);
    address donor = address(this);
    address otherDonor = address(0x456);

    function beforeAll() public {
        charityFund = new DecentralizedCharityFund();
    }

    // test donating and receiving voting power
    /// #value: 1
    function testDonatingAndReceivingVotingPower() public payable {
        // address(this) vote
        uint initialTotalVotingPower = charityFund.totalVotingPower();
        charityFund.donate{value: msg.value}();
        Assert.equal(charityFund.votingPower(donor), msg.value, "Voting power should match the donated amount");
        Assert.equal(charityFund.totalVotingPower(), initialTotalVotingPower + msg.value, "Total voting power should increase by the donated amount");
        Assert.equal(charityFund.hasDonated(donor), true, "Donor should be marked as has donated");
    
        // other donors cannot get voting power
        Assert.notEqual(charityFund.hasDonated(otherDonor), true, "other donor should not be marked as has donated");
    }

    // test submit funding request
    function testSubmittingFundingRequest() public {
        charityFund.submitFundingRequest(projectOwner, 1 wei, "Project 1");
        (address projectAddress, uint256 requestedAmount, string memory projectDescription, , , , bool finalized) = charityFund.projects(0);
        Assert.equal(projectAddress, projectOwner, "Project address should match");
        Assert.equal(requestedAmount, 1 wei, "Requested amount should match");
        Assert.equal(projectDescription, "Project 1", "Project description should match");
        Assert.equal(finalized, false, "Project should not be finalized yet");
    }

    // test vote
    function testVotingOnARequest() public {
        charityFund.voteOnRequest(0);
        (, , , uint256 votes, , , ) = charityFund.projects(0);
        Assert.equal(votes, charityFund.votingPower(donor), "Votes should equal the voter's voting power");

    }

    // can not vote other unexited projects.
    function testVotingOnARequestFail() public {
        bool r;
        string memory message;
        try charityFund.voteOnRequest(10) {
            r = false;
        } catch Error(string memory reason) {
            r = true;
            message = reason;
        }

        Assert.ok(r, message);
    }

    // test finalize request
    function testRequestApprovalAndFundDisbursement() public {
        
        (address testAddr, , , , , , ) = charityFund.projects(0);
        uint initTokens = testAddr.balance;
        Assert.ok(charityFund.finalizeRequest(0), "Should finalize and approve the request");
        (address projectAddress, , , , bool approved, , bool finalized) = charityFund.projects(0);
        Assert.equal(finalized, true, "Request should be finalized");
        Assert.equal(approved, true, "Request should be approved");
        Assert.equal(projectAddress.balance, initTokens + 1, "the project address should get the value");
    }

    // test get funding hitory
    function testGetFundingHistory() public {
        (address[] memory addresses, uint[] memory amounts, string[] memory descriptions) = charityFund.getFundingHistory();
        Assert.equal(addresses[0], projectOwner, "Project owner address should match in history");
        Assert.equal(amounts[0], 1 wei, "Amount should match in history");
        Assert.equal(descriptions[0], "Project 1", "Description should match in history");
    }
}