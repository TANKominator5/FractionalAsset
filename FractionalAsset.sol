// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FractionalAsset
 * @dev This contract fractionalizes a single ERC721 token into ERC20 tokens.
 * The contract itself holds the NFT as collateral and acts as the ERC20 token
 * contract for the fractions. It also includes a simple governance mechanism.
 */
contract FractionalAsset is ERC20, Ownable, ReentrancyGuard {
    
    // --- State Variables ---

    // The contract address of the original NFT collection (e.g., CryptoPunks, BAYC)
    IERC721 public immutable nftContract;
    
    // The specific token ID of the NFT being fractionalized
    uint256 public immutable nftId;
    
    // Flag to ensure the NFT is locked only once
    bool public isNftLocked;

    // Flag to indicate if the asset has been sold and is ready for redemption
    bool public isRedeemable;

    // --- Events ---

    event NftLocked(address indexed from, uint256 tokenId);
    event AssetRedeemed(address indexed shareholder, uint256 amountPaid, uint256 sharesBurned);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPower);


    // --- Governance Structures ---
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;


    // --- Constructor ---

    /**
     * @param _nftContract The address of the ERC721 contract.
     * @param _nftId The ID of the NFT to fractionalize.
     * @param _name The name for the new fractional ERC20 token (e.g., "Mona Lisa Shares").
     * @param _symbol The symbol for the new token (e.g., "MONA").
     * @param _totalSupply The total number of fractional shares to create.
     * @param _owner The person who is fractionalizing the asset and will receive the shares.
     */
    constructor(
        address _nftContract,
        uint256 _nftId,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _owner
    ) ERC20(_name, _symbol) Ownable(_owner) {
        nftContract = IERC721(_nftContract);
        nftId = _nftId;
        _mint(_owner, _totalSupply);
    }


    // --- Core Functions ---

    /**
     * @dev Locks the NFT inside this contract.
     * The owner of the NFT must first call `approve()` on the NFT contract,
     * giving this contract address permission to take the NFT.
     */
    function lockNft() external onlyOwner {
        require(!isNftLocked, "NFT has already been locked");
        
        // The contract takes custody of the NFT from the owner
        nftContract.safeTransferFrom(owner(), address(this), nftId);
        
        isNftLocked = true;
        emit NftLocked(owner(), nftId);
    }

    /**
     * @notice Allows the contract owner (acting on a passed proposal) to mark the asset as sold.
     * The owner must send the ETH proceeds from the sale into this contract when calling.
     */
    function finalizeSale() external payable onlyOwner {
        require(isNftLocked, "NFT not locked yet");
        require(msg.value > 0, "Must send ETH proceeds");
        isRedeemable = true;
    }
    
    /**
     * @notice Allows a shareholder to burn their shares in exchange for their portion of the sale proceeds.
     */
    function redeemShares() external nonReentrant {
        require(isRedeemable, "Asset is not yet redeemable");
        
        uint256 userShares = balanceOf(msg.sender);
        require(userShares > 0, "You have no shares to redeem");

        // Calculate the user's portion of the total ETH held by the contract
        uint256 totalEth = address(this).balance;
        uint256 ethToSend = (totalEth * userShares) / totalSupply();

        // Burn the user's shares
        _burn(msg.sender, userShares);
        
        // Send the ETH
        (bool success, ) = msg.sender.call{value: ethToSend}("");
        require(success, "ETH transfer failed");

        emit AssetRedeemed(msg.sender, ethToSend, userShares);
    }


    // --- Governance Functions ---

    /**
     * @notice Create a new governance proposal.
     */
    function createProposal(string calldata _description, uint256 _votingDays) external {
        require(balanceOf(msg.sender) > 0, "Must be a shareholder to create proposal");
        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + (_votingDays * 1 days);
        emit GovernanceProposalCreated(proposalCounter, _description);
    }
    
    /**
     * @notice Vote on an active proposal.
     */
    function vote(uint256 _proposalId, bool _supportsProposal) external {
        Proposal storage p = proposals[_proposalId];
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Proposal does not exist");
        require(block.timestamp < p.deadline, "Voting period has ended");
        require(!p.hasVoted[msg.sender], "You have already voted");

        uint256 votingPower = balanceOf(msg.sender);
        require(votingPower > 0, "You have no voting power");
        
        if (_supportsProposal) {
            p.yesVotes += votingPower;
        } else {
            p.noVotes += votingPower;
        }
        
        p.hasVoted[msg.sender] = true;
        emit VotedOnProposal(_proposalId, msg.sender, _supportsProposal, votingPower);
    }
}