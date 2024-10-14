// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Vault {
    /// @notice Event emitted when Ether is received
    /// @param sender The address that sent Ether
    /// @param amount The amount of Ether sent
    event EtherReceived(address indexed sender, uint256 amount);

    /// @notice Event emitted when Ether reward is paid out
    /// @param recipient The address receiving the reward
    /// @param amount The amount of Ether paid out
    /// @param reason The reason for the reward
    event RewardPayedOut(address indexed recipient, uint256 amount, string reason);

    /// @notice Event emitted when an NFT is received
    /// @param sender The address that sent the NFT
    /// @param nftId The ID of the received NFT
    event NftReceived(address indexed sender, uint256 nftId);

    /// @notice Event emitted when NFTs are rewarded
    /// @param recipient The address receiving the NFTs
    /// @param message A message describing the reward
    event NftsRewarded(address indexed recipient, string message);

    /// @notice Time when the Ether reward period ends
    uint256 public endAt;

    /// @notice Last address that sent Ether to the contract
    address payable public lastAddress;

    /// @notice Time when the NFT reward period ends
    uint256 public endAtNft;

    /// @notice Last address that sent an NFT to the contract
    address public lastNftAddress;

    /// @notice List of NFT IDs stored in the contract
    uint256[] public nftIds;

    /// @notice Address of the ThreeSigma NFT contract
    address public nftAddress;

    /// @notice Initializes the Vault contract and sets initial values
    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        endAt = 0;
        lastAddress = payable(0);
        endAtNft = 0;
        lastNftAddress = address(0);
    }

    /// @notice Allows users to send Ether to the contract and participate in the Ether reward pool
    /// @dev If the countdown timer is active, it resets to 1 minute after each deposit
    function sendEther() external payable {
        require(msg.value > 0, "Ether value must be more than 0.");
        if (endAt == 0) {
            endAt = block.timestamp + 1 minutes;
        }

        if (block.timestamp < endAt) {
            lastAddress = payable(msg.sender);
            endAt = block.timestamp + 1 minutes;
            emit EtherReceived(msg.sender, msg.value);
        }
    }

    /// @notice Allows the last person who sent Ether to claim all the Ether in the contract
    /// @dev Can only be called when the timer expires
    function claimEther() external payable {
        require(msg.sender == lastAddress, "Only the winner can claim the funds.");
        require(block.timestamp >= endAt, "The competition hasn't finished yet.");

        // Pay out the ether
        emit RewardPayedOut(msg.sender, address(this).balance, "Reward claimed, congratulations!");
        lastAddress.transfer(address(this).balance);

        // Reset the game state
        endAt = 0;
        lastAddress = payable(0);
    }

    /// @notice Allows users to send an NFT to the contract and participate in the NFT reward pool
    /// @param _nftId The ID of the NFT to deposit
    /// @dev Transfers the NFT to the contract and resets the countdown timer
    function sendNft(uint256 _nftId) external {
        require(ERC721(nftAddress).ownerOf(_nftId) == msg.sender, "You do not own this NFT");
        if (endAtNft == 0) {
            endAtNft = block.timestamp + 1 minutes;
        }

        if (block.timestamp < endAtNft) {
            ERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);
            endAtNft = block.timestamp + 1 minutes;
            lastNftAddress = msg.sender;
            nftIds.push(_nftId);
            emit NftReceived(msg.sender, _nftId);
        }
    }

    /// @notice Allows the last person who sent an NFT to claim all the NFTs in the contract
    /// @dev Can only be called when the timer expires
    function claimNfts() external {
        require(msg.sender == lastNftAddress, "Only the last depositor can claim the NFTs");
        require(block.timestamp >= endAtNft, "The timer has not yet expired");

        for (uint256 i = 0; i < nftIds.length; i++) {
            ERC721(nftAddress).safeTransferFrom(address(this), lastNftAddress, nftIds[i]);
        }

        // Reset the nftIds array after transferring all NFTs
        delete nftIds;

        // Reset the game state
        endAtNft = 0;
        lastNftAddress = address(0);
        emit NftsRewarded(msg.sender, "All ThreeSigmaNFTs sent");
    }
}