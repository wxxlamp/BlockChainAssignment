// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAuctionHouse is ReentrancyGuard {
    struct Auction {
        // artist
        address payable artist;
        string itemName;
        uint256 reservePrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        // whether the auction finalized or not
        bool finalized;
        // whether the auction finalized or not
        bool artworkTransferred;
    }

    // auction count, which is the index of auctions
    uint256 public auctionCount;
    // each auction
    mapping(uint256 => Auction) public auctions;
    // can withdraw amount for user in each auction
    mapping(uint256 => mapping(address => uint256)) public bids;

    // event
    event AuctionCreated(uint256 auctionId, string itemName, uint256 reservePrice, uint256 auctionDuration);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event BidWithdrawn(uint256 auctionId, address bidder, uint256 amount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 amount);
    event ArtworkTransferred(uint256 auctionId, address from, address to, string itemName);
    event AuctionExtension(uint256 auctionId, address bidder, uint256 newEndTime);

    constructor() {}

    function createAuction(string memory itemName, uint256 reservePrice, uint256 auctionDuration) external {
        auctionCount++;
        auctions[auctionCount] = Auction({
            artist: payable(msg.sender),
            itemName: itemName,
            reservePrice: reservePrice,
            endTime: block.timestamp + auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            finalized: false,
            artworkTransferred: false
        });

        emit AuctionCreated(auctionCount, itemName, reservePrice, auctionDuration);
    }

    function placeBid(uint256 auctionId) external payable nonReentrant {
        _ensureAuctionExists(auctionId);
        Auction storage auction = auctions[auctionId];
        // cannot place bid when auction ended
        require(block.timestamp < auction.endTime, "Auction ended");
        // user cannot place bid if they are lower can the highest bidder
        require(msg.value > auction.highestBid, "Bid too low than the highest bid");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            bids[auctionId][auction.highestBidder] += auction.highestBid;
        }

        // reset this buyer to be the highest bidder.
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function withdrawBid(uint256 auctionId) external nonReentrant {
        _ensureAuctionExists(auctionId);
        Auction storage auction = auctions[auctionId];
        // buyer can only withdraw when action is processing
        require(block.timestamp < auction.endTime, "Auction ended");
        // get the withdraw amount for msg.sender
        uint256 amount = bids[auctionId][msg.sender];
        require(amount > 0, "No amount to withdraw");
        // highest bidder cannot withdraw
        require(msg.sender != auction.highestBidder, "Highest bidder cannot withdraw");

        // reset the withdraw amount
        bids[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BidWithdrawn(auctionId, msg.sender, amount);
    }

    function finalizeAuction(uint256 auctionId) external nonReentrant {
        _ensureAuctionExists(auctionId);
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        require(!auction.finalized, "Auction already finalized");
        require(msg.sender == auction.artist, "Only artist can finalize");

        // if there is a valid bids
        if (auction.highestBidder != address(0)) {
            auction.artist.transfer(auction.highestBid);
            // Transfer ownership of the digital artwork
            auction.artworkTransferred = true;
            // finalize the auction
            auction.finalized = true;
            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBid);
            emit ArtworkTransferred(auctionId, auction.artist, auction.highestBidder, auction.itemName);
        } else {
            // If no valid bids, extend the auction with 1 day.
            auction.endTime = block.timestamp + 1 days;
            auction.finalized = false;
            emit AuctionExtension(auctionId, auction.artist, auction.endTime);
        }
    }

    // return the details of auction with its name, reserve price, end time and whether finalized or not
    function getAuctionDetails(uint256 auctionId) external view returns (string memory, uint256, uint256, bool) {
        _ensureAuctionExists(auctionId);
        Auction storage auction = auctions[auctionId];
        return (auction.itemName, auction.reservePrice, auction.endTime, auction.finalized);
    }

    function _ensureAuctionExists(uint256 auctionId) internal view {
        require(auctionId > 0 && auctionId <= auctionCount, "Auction does not exist");
    }
}
