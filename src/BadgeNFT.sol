// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title BadgeNFT
 * @dev NFT badge minted when users successfully complete their first flash loan
 */
contract BadgeNFT is ERC721, Ownable {
    using Strings for uint256;

    // Events
    event BadgeMinted(address indexed recipient, uint256 indexed tokenId);

    // State variables
    uint256 private _tokenIdCounter;
    mapping(address => uint256) public userTokenId; // Track which token ID a user owns
    mapping(uint256 => address) public tokenIdToUser; // Track which user owns a token ID
    mapping(address => bool) public hasBadge; // Quick lookup for badge ownership
    
    // Flash loan provider that can mint badges
    address public flashLoanProvider;
    
    // Metadata
    string private _baseTokenURI;
    string public constant BADGE_DESCRIPTION = "Flash Loan Master Badge - Awarded for successfully completing your first flash loan on Monad testnet";

    constructor(
        string memory name,
        string memory symbol,
        address _flashLoanProvider
    ) ERC721(name, symbol) Ownable(msg.sender) {
        flashLoanProvider = _flashLoanProvider;
        _baseTokenURI = "https://api.flashloan-playground.com/metadata/";
    }

    /**
     * @dev Mint a badge to a user (only callable by flash loan provider)
     * @param to The address to mint the badge to
     * @return tokenId The ID of the minted token
     */
    function mintBadge(address to) external returns (uint256 tokenId) {
        require(msg.sender == flashLoanProvider, "Only flash loan provider can mint");
        require(to != address(0), "Cannot mint to zero address");
        require(!hasBadge[to], "User already has a badge");

        tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // Mint the NFT
        _safeMint(to, tokenId);
        
        // Update mappings
        userTokenId[to] = tokenId;
        tokenIdToUser[tokenId] = to;
        hasBadge[to] = true;

        emit BadgeMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Set the flash loan provider address (owner only)
     * @param _flashLoanProvider New flash loan provider address
     */
    function setFlashLoanProvider(address _flashLoanProvider) external onlyOwner {
        require(_flashLoanProvider != address(0), "Invalid provider address");
        flashLoanProvider = _flashLoanProvider;
    }

    /**
     * @dev Set the base URI for token metadata (owner only)
     * @param baseURI New base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Get the token ID owned by a user
     * @param user The user address
     * @return tokenId The token ID (returns type(uint256).max if no badge)
     */
    function getUserTokenId(address user) external view returns (uint256 tokenId) {
        if (hasBadge[user]) {
            return userTokenId[user];
        }
        return type(uint256).max; // Indicates no badge
    }

    /**
     * @dev Check if a user has earned a badge
     * @param user The user address
     * @return Whether the user has a badge
     */
    function hasEarnedBadge(address user) external view returns (bool) {
        return hasBadge[user];
    }

    /**
     * @dev Get total number of badges minted
     * @return The total number of badges
     */
    function totalBadgesMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Override tokenURI to provide metadata
     * @param tokenId The token ID
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "URI query for nonexistent token");

        return bytes(_baseTokenURI).length > 0
            ? string(abi.encodePacked(_baseTokenURI, tokenId.toString()))
            : _defaultTokenURI(tokenId);
    }

    /**
     * @dev Generate a default token URI with on-chain metadata
     * @param tokenId The token ID
     * @return JSON metadata string
     */
    function _defaultTokenURI(uint256 tokenId) internal view returns (string memory) {
        address owner = ownerOf(tokenId);
        
        string memory json = string(
            abi.encodePacked(
                'data:application/json,{"name":"Flash Loan Master Badge #',
                tokenId.toString(),
                '","description":"',
                BADGE_DESCRIPTION,
                '","owner":"',
                Strings.toHexString(uint256(uint160(owner)), 20),
                '","attributes":[{"trait_type":"Achievement","value":"First Flash Loan"},{"trait_type":"Network","value":"Monad Testnet"},{"trait_type":"Badge Type","value":"Flash Loan Master"}]}'
            )
        );
        
        return json;
    }

    /**
     * @dev Override transfer functions to make badges non-transferable (soulbound)
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0)) but prevent transfers
        require(from == address(0), "Badges are non-transferable (soulbound)");
        
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Override approve to prevent approvals (since badges are soulbound)
     */
    function approve(address /* to */, uint256 /* tokenId */) public virtual override {
        revert("Badges are non-transferable (soulbound)");
    }

    /**
     * @dev Override setApprovalForAll to prevent approvals (since badges are soulbound)
     */
    function setApprovalForAll(address /* operator */, bool /* approved */) public virtual override {
        revert("Badges are non-transferable (soulbound)");
    }
}
