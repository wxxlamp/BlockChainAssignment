// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedCharityFund {
    // Define data structures
    struct FundingProject {
        address projectAddress;
        uint256 requestedAmount;
        string projectDescription;
        uint256 votes;
        bool approved;
        // setting the project owner to preventing the project is finalized by others
        address owner;
        // check the project is finalized or not
        bool finalized;
    }

    // the charitable projects
    FundingProject[] public projects;
    // every Donors' voting power
    mapping(address => uint256) public votingPower;
    // check the donor donate or not
    mapping(address => bool) public hasDonated;
    // total voting power, increaing when donor donate.
    uint256 public totalVotingPower;

    // Emit events for off-chain tracking
    event DonationReceived(address indexed donor, uint256 amount);
    event RequestSubmitted(uint256 indexed requestId, address projectAddress, uint256 amount, string description);
    event RequestVoted(uint256 indexed requestId, address voter, uint256 power);
    event RequestFinalized(uint256 indexed requestId, bool approved);

    constructor() {}

    // Donate function allows donors to contribute Ether and get voting power
    function donate() external payable {
        require(msg.value > 0, "Donation must be more than 0");
        
        votingPower[msg.sender] += msg.value;
        totalVotingPower += msg.value;
        hasDonated[msg.sender] = true;

        emit DonationReceived(msg.sender, msg.value);
    }

    // Function for projects to submit funding requests
    function submitFundingRequest(address projectAddress, uint256 requestedAmount, string memory projectDescription) external {
        projects.push(FundingProject({
            projectAddress: projectAddress,
            requestedAmount: requestedAmount,
            projectDescription: projectDescription,
            votes: 0,
            approved: false,
            owner: msg.sender,
            finalized: false
        }));

        emit RequestSubmitted(projects.length - 1, projectAddress, requestedAmount, projectDescription);
    }

    // Voting on requests for donors with voting power
    function voteOnRequest(uint256 requestId) external returns (bool) {
        require(hasDonated[msg.sender], "Must be a donor to vote");
        require(requestId < projects.length, "Invalid request ID");
        require(!projects[requestId].finalized, "Request already finalized");

        FundingProject storage request = projects[requestId];
        request.votes += votingPower[msg.sender];

        emit RequestVoted(requestId, msg.sender, votingPower[msg.sender]);
        return true;
    }

    // Finalize the funding request, disburse funds if approved
    function finalizeRequest(uint256 requestId) external returns (bool) {
        require(requestId < projects.length, "Invalid request ID");
        require(!projects[requestId].finalized, "Request already finalized");
        require(msg.sender == projects[requestId].owner, "Finalize operator must be the project's owner");

        FundingProject storage request = projects[requestId];

        // check the votes is larger than 50%
        if (request.votes > totalVotingPower / 2) {
            request.approved = true;
            payable(request.projectAddress).transfer(request.requestedAmount);
        }

        projects[requestId].finalized = true;
        emit RequestFinalized(requestId, request.approved);

        return request.approved;
    }

    // Provides the funding history
    function getFundingHistory() external view returns (address[] memory, uint256[] memory, string[] memory) {
        uint256 length = projects.length;
        address[] memory addresses = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        string[] memory descriptions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            FundingProject memory request = projects[i];
            addresses[i] = request.projectAddress;
            amounts[i] = request.requestedAmount;
            descriptions[i] = request.projectDescription;
        }
        return (addresses, amounts, descriptions);
    }
}
