# CSIT 6000Q - Blockchain and Smart Contracts Assignment 2

1. In all Solidity programs, I prefer to record operations using the `event` keyword to ensure the stability of my programs.
2. The Solidity code is well-documented and adheres to best practices in Solidity programming. Refer to the [Solidity Style Guide](https://learnblockchain.cn/docs/solidity/style-guide.html#id16) for more details.
3. The code and README file have been uploaded to GitHub: [BlockChainAssignment - Assignment 2](https://github.com/wxxlamp/BlockChainAssignment/tree/main/contracts/assignment2)

## 1. DecentralizedCharityFund

### 1.1. Contract Structure

#### 1.1.1. Structs

- **FundingProject**: A struct that manages details of each charitable project.

- - `projectAddress`: The address associated with the project.
  - `requestedAmount`: The amount of funds requested by the project.
  - `projectDescription`: A brief description of the project.
  - `votes`: Number of votes the project has received.
  - `approved`: Boolean indicating if the project is approved for funding.
  - `owner`: The address of the project owner to prevent unauthorized finalization.
  - `finalized`: Boolean indicating whether the request process has been finalized.

#### 1.1.2. Mappings

- **votingPower**: Tracks each donor's voting power based on their contributions.
- **hasDonated**: Boolean mapping to indicate if an address has made a donation.
- **donorHasVoted**: Check donor has voted or not for projects.

#### 1.1.3. Fields

- **totalVotingPower**: A cumulative total of all donors' voting power.

#### 1.1.4. Events

- **DonationReceived**: Emitted when a donor contributes, logging the donor's address and donation amount.
- **RequestSubmitted**: Emitted when a new funding request is submitted, detailing the request ID, project address, requested amount, and description.
- **RequestVoted**: Emitted when a vote is cast on a funding request, including the request ID, voter's address, and voting power used.
- **RequestFinalized**: Emitted when a funding request is finalized, noting the request ID and approval status.

### 1.2. Contract Functions

- **constructor**: Initializes the decentralized charity fund system, setting up initial conditions and mappings.
- **donate**:

- - Checks that the donation amount is greater than zero.
  - Allows individuals to contribute Ether, thus gaining voting power.
  - Increments the voting power for the donor and the total voting power.
  - Emits a `DonationReceived` event upon successful donation.

- **submitFundingRequest**:

- - Enables project owners to submit new funding requests.
  - Saves the request and emits a `RequestSubmitted` event.

- **voteOnRequest**:

- - Allows donors with voting power to vote on funding requests.
  - Validates donor status and ensures request is not yet finalized. Restrict donor has only one chance to vote for a project to prevent the funding request getting approval by a single user who lacks enough vote power.
  - Adds the donor's voting power to the request's vote total.
  - Emits a `RequestVoted` event upon successful voting.

- **finalizeRequest**:

- - Only permits project owners to finalize their submitted requests and ensures the request is eligible for finalization.
  - Disburses funds to the project address if >50% of total voting power approves the request.
  - Updates request status and emits a `RequestFinalized` event.

- **getFundingHistory**:

- - Provides a summary of all funding requests.
  - Returns arrays of project addresses, requested amounts, and project descriptions.

## 2. FanEngagementSystem

### 2.1 Key Notes

* The smart contract utilizes OpenZeppelin's ERC20 and ERC721 standards to manage reward tokens and NFT badges.
* The owner mechanism is effective using OpenZeppelin's Ownable template.

### 2.2. Contract Structure

#### 2.2.1. Contract

- **RewardToken**：A contract utilizing OpenZeppelin's ERC20 abstract contract is employed to manage reward tokens, especially burn and earn.
- **NFTBadge**：A contract utilizing OpenZeppelin's ERC721URIStorage abstract contract is employed to manage NFT badges.

#### 2.2.2. Structs

- **Proposal**: A struct designed to store details of each proposal submitted by users. It includes:

- - `owner`: The address of the user who submitted the proposal.
  - `description`: A brief explanation of the proposal.
  - `voteCount`: The total number of votes the proposal has received.

#### 2.2.3. Mappings

- **proposalVotes**: Tracks whether a specific user has voted on a particular proposal, preventing duplicate votes.
- **rewardHistory**: Maintains a log of the types of rewards redeemed by each fan.

#### 2.2.4. Events

- **TokensEarned**: Emitted when a fan earns tokens, specifying the fan's address, amount earned, and the activity type related to the earnings.
- **TokensTransferred**: Emitted upon the successful transfer of tokens between fans, noting the sender, recipient, and amount transferred.
- **TokensRedeemed**: Emitted when tokens are redeemed by a fan for a reward, indicating the fan's address, amount redeemed, and type of reward.
- **NFTBadgeMinted**: Triggered when an NFT badge is minted for a fan, including the fan's address and the badge name.
- **ProposalSubmitted**: Emitted when a proposal is submitted, logging the proposal ID and its description.
- **VotedOnProposal**: Emitted when a fan votes on a proposal, detailing the proposal ID and the voter's address.

### 2.3. Contract Functions

- **constructor**: 

- - Initializes the Fan Engagement System by creating instances of `RewardToken` and `NFTBadge` contracts which implement OpenZeppelin's ERC20 and ERC721URIStorage abstract contracts.
  - The contract initializes owner to control only the contract owner can call them to mint and distribute tokens to fans.
  - The contract allocates an initial amount of 180,000,000 reward tokens to ensure there are enough tokens for fans to earn.

- **earnTokens**:

- - When fans participate in activities and submit proof, the contract owner will transfer reward tokens from the initial pool once fans’ proofs are verified
  - As the question does not define a specific verifier, my solution assumes that the proof should not be empty.

- **transferTokens**:

- - Checks for sufficient balance before transferring tokens.
  - Enables fans to transfer their reward tokens to other users.

- **redeemTokens**:

- - Allows fans to exchange tokens for rewards, burning the tokens in the process by calling `ERC20#_burn` method.
  - The transaction will be recorded in `rewardHistory`, which can be viewed by any fan.

- **mintNFTBadge**:

- - Allows the contract owner to mint NFT badges for fans throught `NFTBadge` contract.
  - Mints an NFT token with a specified URI and emits an `NFTBadgeMinted` event.

- **submitProposal**:

- - Permits fans holding reward tokens to submit proposals.
  - Records the proposal and emits a `ProposalSubmitted` event.

- **voteOnProposal**:

- - Allows fans with tokens to vote on submitted proposals using their proposal ID. Fans who voted cannot vote again.
  - Updates the vote count and emits a `VotedOnProposal` event to prevent double-voting.

- **getFanLoyaltyTier**:

- - Use the `ERC20#balance` function to obtain the token count for each fan to implement a feature for classifying fans into different loyalty tiers
  - Returns "Gold" for balances over 1,000, "Silver" for over 500, and "Bronze" for others.

- **getRewardHistory**:

- - Provides the reward redemption history of a specific fan using the field `rewardHistory`

## 3. RentalAgreementManagement

### 3.1. Contract Structure

#### 3.1.1. Enums and Structs

- **AgreementStatus**: An enumeration to represent the possible states of a rental agreement: `Unactive`, `Active`, and `Terminated`. Among them, `Unactive`stands for there is no data of current agreement.
- **Agreement**: A struct detailing the specifics of each rental agreement, including landlord, tenant details, rent, duration, status, and payment count.

#### 3.1.2. Mappings

- **agreements**: Maps a unique identifier to each rental agreement. The key is increase followed by the `Counters` template of OpenZeppelin.
- **paymentHistory**: Keeps track of the timestamps for each rent payment made under a given agreement.

#### 3.1.3. Events

- **AgreementCreated**: Emitted when a new agreement is established, logging the landlord, tenant, rent amount, and duration.
- **RentPaid**: Emitted upon a successful rent payment, noting the tenant, payment amount, and timestamp.
- **AgreementTerminated**: Emitted when an agreement is terminated, detailing whether the agreement ended due to completion or violation.

### 3.2. Contract Functions

- **constructor**: Initializes the rental agreement management system. No special parameters are set during construction.
- **createAgreement**:

- - Allows landlords to create new rental agreements.
  - Takes tenant address, rent amount, and duration as parameters.
  - Stores agreement details and emits an `AgreementCreated` event.

- **payRent**:

- - Enables tenants to make rent payments corresponding to their agreement.
  - Validates that the caller is the right tenant and the payment is correct.
  - Transfer the payment from tenant to landord.
  - Updates payment records and emits a `RentPaid` event.

- **terminateAgreement**:

- - Permits landlords to terminate an existing active rental agreement for any reason.
  - Verifies authorization and updates the agreement status.
  - Emits an `AgreementTerminated` event to acknowledge the termination.

- **getAgreementStatus**:

- - Returns a string indicating the current status of a specific rental agreement (`Active`, `Terminated`, or `Unknown`).

## 4. DecentralizedAuctionHouse

### 4.1. Key Notes

- The contract uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
- The contract includes mechanisms to handle auction extensions if no valid bids are placed.
- The contract ensures that the highest bidder cannot withdraw their bid to prevent malicious behavior.

### 4.2. Contract Structure

#### 4.2.1. Structs

- **Auction**: A struct detailing the specifics of each auction, including:

- - `artist`: The address of the artist who created the auction. It's payable for transfer.
  - `itemName`: The name of the digital artwork.
  - `reservePrice`: The minimum price the artist is willing to accept.
  - `endTime`: The timestamp when the auction ends.
  - `highestBidder`: The address of the highest bidder.
  - `highestBid`: The highest bid amount.
  - `finalized`: A boolean indicating whether the auction has been finalized.
  - `artworkTransferred`: A boolean indicating whether the ownership of the artwork has been transferred.

#### 4.2.2. Mappings

- **auctions**: Maps a unique identifier to each auction. The key is an incrementing counter.
- **bids**: Maps a specific auction ID and bidder address to the amount of their bid, allowing bidders to withdraw their bids if they are not the highest bidder.

#### 4.2.3. Events

- **AuctionCreated**: Emitted when a new auction is created, logging the auction ID, item name, reserve price, and auction duration.
- **BidPlaced**: Emitted when a bid is placed, noting the auction ID, bidder address, and bid amount.
- **BidWithdrawn**: Emitted when a bid is withdrawn, indicating the auction ID, bidder address, and withdrawn amount.
- **AuctionFinalized**: Emitted when an auction is finalized, detailing the auction ID, winning bidder address, and final bid amount.
- **ArtworkTransferred**: Emitted when the ownership of the digital artwork is transferred, noting the auction ID, from address, to address, and item name.
- **AuctionExtension**: Emitted when an auction is extended due to no valid bids, detailing the auction ID, artist address, and new end time.

### 4.3. Contract Functions

- **createAuction**: Allows artists to create new auctions.
- **placeBid**: 

- - Enables buyers to place bids on an auction.
  - Validates that the auction is active, the bid is higher than the current highest bid and reserve price. 
  - Updates the highest bid and bidder, refunds the previous highest bidder, and emits a BidPlaced event.

- **withdrawBid**:

- - Allows bidders to withdraw their bids if they are not the highest bidder and the auction is still active.
  - Validates that the auction is active and the caller is not the highest bidder. 
  - Transfers the bid amount back to the caller and emits a BidWithdrawn event.

- **finalizeAuction:**

- - Allows artists to finalize an auction, transferring ownership and disbursing funds.
  - Validates that the auction has ended and has not been finalized. 
  - If there is a highest bidder, transfers the highest bid to the artist and sets the auction as finalized.
  - If no valid bids, extends the auction by one day and emits an AuctionExtension event.

- **getAuctionDetails**:

- - Returns the details of a specific auction.