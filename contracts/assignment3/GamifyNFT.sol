// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Import IERC20 interface
import "contracts/assignment3/GamifyToken.sol";
import "hardhat/console.sol";

contract GamifyNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    address public erc20Token; // it refers to the GamifyToken
    uint256 public requiredTokenBalance; // Minimum ERC20 tokens required to mint
    uint256 public maxSupply; // Max NFTs that can be minted

    mapping(uint256 => uint256) public level; // Map token ID to level
    mapping(uint256 => uint256) public lastUpdated; // Last time the metadata was updated

    constructor(address _erc20Token) ERC721("GamifyNFT", "GAMNFT") Ownable(msg.sender) {
        tokenCounter = 0;
        erc20Token = _erc20Token;
        requiredTokenBalance = 100 * 10**18; // Default: 100 ERC20 tokens required
        maxSupply = 1000; // Default: Max 1000 NFTs
    }

    // Function to mint an NFT
    function mintNFT(string memory tokenURI) external {
        require(tokenCounter < maxSupply, "Max supply reached");
        // Check if the sender has the required ERC20 token balance
        uint256 userBalance = IERC20(erc20Token).balanceOf(msg.sender);
        require(userBalance >= requiredTokenBalance, "Insufficient ERC20 token balance");

        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        level[newTokenId] = 1; // Start at level 1
        lastUpdated[newTokenId] = block.timestamp;
        tokenCounter++;
        // mark user has the nft to gamifyToken
        GamifyToken(erc20Token).setNFTMark(msg.sender);
    }

    // Function to evolve an NFT (e.g., increase level)
    function evolveNFT(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(block.timestamp - lastUpdated[tokenId] >= 30 days, "NFT can only evolve once per 30 days");

        level[tokenId]++;
        string memory newURI = string(abi.encodePacked("https://metadata.url/level_", uint2str(level[tokenId])));
        _setTokenURI(tokenId, newURI);
        lastUpdated[tokenId] = block.timestamp;
    }

    // Function to set the required ERC20 token balance for minting
    function setRequiredTokenBalance(uint256 _balance) external onlyOwner {
        requiredTokenBalance = _balance;
    }

    // Function to set the maximum supply of NFTs
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    // Helper function to convert a uint to a string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}