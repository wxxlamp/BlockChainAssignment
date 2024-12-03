// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/assignment2/DecentralizedAuctionHouse.sol";

contract DecentralizedAuctionHouseTest is DecentralizedAuctionHouse {

    address bidder1 = TestsAccounts.getAccount(2);
    address bidder2 = TestsAccounts.getAccount(3);

    // create auction for account-1 and check by getAuctionDetails
    /// #sender: account-1
    function testCreateAuction() public {
        super.createAuction("Artwork 1", 1 ether, 1 days);
        (string memory itemName, uint256 reservePrice, uint256 endTime, bool finalized) = this.getAuctionDetails(1);
        Assert.equal(itemName, "Artwork 1", "Item name should match");
        Assert.equal(reservePrice, 1 ether, "Reserve price should match");
        Assert.ok(endTime > block.timestamp, "End time should be in the future");
        Assert.equal(finalized, false, "Auction should not be finalized");
    }

    // bidder1 place a bid and success
    /// #sender: account-2
    /// #value: 2000000000000000000 // 2 Ether
    function testPlaceBid() public payable {

        super.placeBid(1);
        (,, , ,address highestBidder, uint256 highestBid,,) = this.auctions(1);
        Assert.equal(highestBidder, bidder1, "Bidder 1 should be the highest bidder");
        Assert.equal(highestBid, msg.value, "Highest bid should match the bid amount");
    }

    // bidder1 place a higher bid and success
    /// #sender: account-2
    /// #value: 3000000000000000000 // 3 Ether
    function testPlaceHigherBid() public payable {
        super.placeBid(1);
        (,, , ,address highestBidder, uint256 highestBid,,) = this.auctions(1);
        Assert.equal(highestBidder, bidder1, "Bidder 1 should still be the highest bidder");
        Assert.equal(highestBid, 3 ether, "Highest bid should be updated to 3 Ether");
    }

    // bidder2 place the highest bid and success
    /// #sender: account-3
    /// #value: 4000000000000000000 // 4 Ether
    function testPlaceHighestBid() public payable {
        super.placeBid(1);
        (,, , ,address highestBidder, uint256 highestBid,,) = this.auctions(1);
        Assert.equal(highestBidder, bidder2, "bidder2 be the highest bidder");
        Assert.equal(highestBid, 4 ether, "Highest bid should be updated to 4 Ether");
    }

    // the highest bidder(2) cannot withdraw
    /// #sender: account-3
    function testWithdrawBidAsHighestBidder() public {
        // Attempt to withdraw as the highest bidder
        bool r;
        (r, ) = address(this).call(abi.encodeWithSignature("withdrawBid(uint256)", 1));
        Assert.ok(!r, "Highest bidder should not be able to withdraw their bid");
    }

    // bidder1 with low bid cannot place a bid
    /// #sender: account-2
    function testBidTooLow() public payable {
        // Attempt to place a lower bid
        bool r;
        (r, ) = address(this).call{value: 1 ether}(abi.encodeWithSignature("placeBid(uint256)", 1));
        Assert.ok(!r, "Should not allow a bid lower than the highest bid");
    }

    // bidder1 with the low bid can withdraw
    /// #sender: account-2
    function testWithdrawBid() public {
        uint initValue = bidder1.balance;
        // Bidder 1 withdraws their bid
        super.withdrawBid(1);
        // Check that Bidder 1's bid is reset
        (,, , ,address highestBidder,,,) = this.auctions(1);
        Assert.equal(highestBidder, bidder2, "Bidder 2 should be the highest bidder after withdrawal");
        // bidder1 can withdraw his bid.
        Assert.equal(initValue + 5 ether, bidder1.balance, "Bidder 1's balance");
    }

    // finalize the auction
    /// #sender: account-1
    function testFinalizeAuction() public {
        uint initBalance = TestsAccounts.getAccount(1).balance;
        // revert the endTime for auction 1 to enable it finalize.
        auctions[1].endTime = 0;
        super.finalizeAuction(1);
        (,,,bool finalized) = this.getAuctionDetails(1);
        Assert.ok(finalized, "Auction should be finalized after completion");
        Assert.equal(TestsAccounts.getAccount(1).balance, initBalance + 4 ether, "Account 1's balance");
    }

    // Auction should not be finalized if there are no bids, and the auction should be extended.
    /// #sender: account-1
    function testFinalizeAuctionNoBids() public {
        super.createAuction("Artwork 2", 1 ether, 0);
        // Finalize auction
        super.finalizeAuction(2);
        (,,,uint endtime,,,bool finalized,) = this.auctions(2);
        Assert.ok(!finalized, "Auction should not be finalized if there are no bids");
        Assert.ok(endtime > 1 days, "Auction should extend to 1 day");
    }
}