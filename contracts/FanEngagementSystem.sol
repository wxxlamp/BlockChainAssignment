// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ERC20 token contract for reward tokens
contract RewardToken is ERC20 {
    constructor() ERC20("SimpleToken", "RT") {
        // Initial allocation to the contract owner to distribute rewards
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // destory user's token
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
}

// ERC721 token contract for NFT badges
contract NFTBadge is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("SimpleNFT", "NFTB") {}

    // mint nft tokens
    function mintToken(address to, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
}

// Main contract for fan engagement and reward system
contract FanEngagementSystem is Ownable {
    struct Proposal {
        address owner;
        string description;
        uint256 voteCount;
    }

    RewardToken internal rewardToken;
    NFTBadge internal nftBadge;

    // each proposals
    Proposal[] internal proposals;
    // the vote state of proposals
    mapping(address => mapping(uint256 => bool)) public proposalVotes;
    // Tracks fans' reward history
    mapping(address => string[]) internal rewardHistory; 

    event TokensEarned(address indexed fan, uint256 amount, string activityType);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event TokensRedeemed(address indexed fan, uint256 amount, string rewardType);
    event NFTBadgeMinted(address indexed fan, string badgeName);
    event ProposalSubmitted(uint256 indexed proposalId, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed fan);

    constructor() Ownable(msg.sender) {
        rewardToken = new RewardToken();
        nftBadge = new NFTBadge();
    }

    // Function to earn tokens based on fan activities
    function earnTokens(address fan, uint256 amount, string memory activityType, string memory activityProof) public onlyOwner {
        
        // verify the activity proof goes here, activity proof must not be empty
        require(keccak256(bytes(activityProof)) != keccak256(bytes("")), "verify error");

        rewardToken.transfer(fan, amount);
        emit TokensEarned(fan, amount, activityType);
    }

    // Function to transfer tokens between fans
    function transferTokens(address to, uint256 amount) public {
        require(rewardToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        rewardToken.transfer(to, amount);
        emit TokensTransferred(msg.sender, to, amount);
    }

    // Function to redeem tokens for rewards
    function redeemTokens(uint256 amount, string memory rewardType) public {
        require(rewardToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        rewardToken.burn(amount);
        rewardHistory[msg.sender].push(rewardType);
        emit TokensRedeemed(msg.sender, amount, rewardType);
    }

    // Function to mint NFT badges for fans
    function mintNFTBadge(address fan, string memory badgeName) public onlyOwner {
        // Minting NFT Logic
        nftBadge.mintToken(fan, badgeName);
        emit NFTBadgeMinted(fan, badgeName);
    }

    // Function to submit a proposal
    function submitProposal(string memory proposalDescription) public {
        // only user hold token can submit proposal
        require(rewardToken.balanceOf(msg.sender) > 0, "user must have token to submit proposal");
        proposals.push(Proposal(msg.sender, proposalDescription, 0));
        emit ProposalSubmitted(proposals.length - 1, proposalDescription);
    }

    // Function to vote on a proposal
    function voteOnProposal(uint256 proposalId) public {
        // only user hold token can vote proposal
        require(rewardToken.balanceOf(msg.sender) > 0, "user must have token to vote proposal");
        require(!proposalVotes[msg.sender][proposalId], "Already voted");
        require(proposalId < proposals.length, "Invalid proposalId ID");
        proposals[proposalId].voteCount++;
        proposalVotes[msg.sender][proposalId] = true;
        emit VotedOnProposal(proposalId, msg.sender);
    }

    // Function to get a fan's loyalty tier
    function getFanLoyaltyTier(address fan) public view returns (string memory) {
        uint256 points = rewardToken.balanceOf(fan);
        if (points >= 1000) {
            return "Gold";
        } else if (points >= 500) {
            return "Silver";
        } else {
            return "Bronze";
        }
    }

    // Function to get a fan's reward history
    function getRewardHistory(address fan) public view returns (string[] memory) {
        return rewardHistory[fan];
    }
}
