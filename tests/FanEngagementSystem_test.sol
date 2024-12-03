// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_accounts.sol";
import "remix_tests.sol"; 
import "hardhat/console.sol";
import "../contracts/assignment2/FanEngagementSystem.sol";

contract FanEngagementSystemTest is FanEngagementSystem {

    address testOwner = TestsAccounts.getAccount(0);
    address fan1 = TestsAccounts.getAccount(1);
    address fan2 = TestsAccounts.getAccount(2);
    address fan3 = TestsAccounts.getAccount(3);

    // test the remaining token
    function testTotolSupplyTokens() public {
        uint supplyTokens = super.totalSupply();
        Assert.equal(supplyTokens, 1000000 * 10 ** 18, "initial tokens should be 1000000000000000000000000 tokens");
        Assert.equal(super.balanceOf(testOwner), supplyTokens, "test owner has the total supply tokens");
    }

    // owner of this system is account-0
    // test earn 100 tokens for fan1
    /// #sender: account-0
    function testEarnTokens() public {
        super.earnTokens(fan1, 100, "Attended Game", "Proof of attendance");
        uint256 balance = super.balanceOf(fan1);
        Assert.equal(balance, 100, "Fan 1 should have earned 100 tokens");
    }

    // other user cannot earn tokens for fan1
    /// #sender: account-1
    function testEarnTokensWithoutOwner() public {
        bool r;
        (r, ) = address(this).call{value: 1 ether}(abi.encodeWithSignature("address,uint256,string,string", fan1, 50, "Attended Game", "Proof of attendance"));
        Assert.ok(!r, "other user cannot earn tokens for fan1");
    }
    
    // test transfter token for fan1 to fan2
    /// #sender: account-1
    /// #value: 50
    function testTransferTokens() public {
        super.transferTokens(fan2, 50);
        uint256 fan1Balance = super.balanceOf(fan1);
        uint256 fan2Balance = super.balanceOf(fan2);

        Assert.equal(fan2Balance, 50, "Fan 2 should have received 50 tokens");
        Assert.equal(fan1Balance, 50, "Fan 1 should have 50 tokens after transfer");

    }

    // test redeem tokens for fan1, and test get reward history for fan1
    /// #sender: account-1
    function testRedeemTokens() public payable {
        super.redeemTokens(10, "Merchandise");
        uint256 balance = super.balanceOf(fan1);
        Assert.equal(balance, 40, "Fan 1 should have 40 tokens after redemption"); // todo

        string[] memory history = super.getRewardHistory(fan1);
        Assert.equal(history[0], "Merchandise", "Reward history should contain the redeemed reward");
    }

    // fan1 cannot redeem tokens if he doesn't have enough tokens
    /// #sender: account-1
    function testRedeemTokensWithoutEnoughTokens() public payable {
        bool r;
        (r, ) = address(this).call{value: 1 ether}(abi.encodeWithSignature("redeemTokens(uint256,string)", 50, "Merchandise"));
        Assert.ok(!r, "fan1 cannot redeem tokens if he doesn't have enough tokens");
    }

    // fan1 mint nft badge
    /// #sender: account-0
    function testMintNFTBadge() public {
        super.mintNFTBadge(fan1, "Top Fan Badge");
        address badgeOwner = nftBadge.ownerOf(1);
        Assert.equal(badgeOwner, fan1, "Fan 1 should have received an NFT badge");
    }

    // fan1 can submit a proposal
    /// #sender: account-1
    function testSubmitProposal() public {
        super.submitProposal("New Merchandise Idea");
        uint256 proposalId = proposals[0].voteCount;
        Assert.equal(proposalId, 0, "Proposal ID should be 0 for the first proposal");
    }

    // user cannot submit proposal without tokens
    /// #sender: account-3
    function testSubmitProposalRequiresTokens() public {
        // super.submitProposal("test");
        bool r;
        (r, ) = address(this).call(abi.encodeWithSignature("submitProposal(string)", "New Merchandise Idea"));
        Assert.ok(!r, "Should not allow submiting proposal if no tokens are held"); // todo
    }

    // fan2 can vote for proposal 0
    /// #sender: account-2
    function testVoteOnProposal() public {
        super.voteOnProposal(0);
        uint256 voteCount = proposals[0].voteCount;
        Assert.equal(voteCount, 1, "Vote count should be 1 after voting");
    }

    // user cannot vote without tokens
    /// #sender: account-3
    function testVoteRequiresTokens() public {
        bool r;
        (r, ) = address(this).call(abi.encodeWithSignature("voteOnProposal(uint256)", 0));
        Assert.ok(!r, "Should not allow voting if no tokens are held"); // todo
    }

    // user can get gold level with over 1000 tokens
    /// #sender: account-0
    function testGetFanLoyaltyTier() public {
        super.earnTokens(fan1, 1000, "Attended Game", "Proof of attendance");
        string memory tier = super.getFanLoyaltyTier(fan1);
        Assert.equal(tier, "Gold", "Fan 1 should be in Gold tier");
    }
}