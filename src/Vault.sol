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
    /// @param message The message for the payout
    event RewardPayedOut(address indexed recipient, uint256 amount, string message);

    /// @notice Event emitted when an NFT is received
    /// @param sender The address that sent the NFT
    /// @param nftId The ID of the received NFT
    event NftReceived(address indexed sender, uint256 nftId);

    /// @notice Event emitted when NFTs are rewarded
    /// @param recipient The address receiving the NFTs
    /// @param message A message describing the reward
    event NftsRewarded(address indexed recipient, string message);

    /// @notice Time when the Ether reward period ends
    uint256 internal endAt;

    /// @notice Last address that sent Ether to the contract
    address payable internal lastAddress;

    /// @notice Time when the NFT reward period ends
    uint256 internal endAtNft;

    /// @notice Last address that sent an NFT to the contract
    address internal lastNftAddress;

    /// @notice List of NFT IDs stored in the contract
    uint256[] internal nftIds;

    /// @notice Address of the ThreeSigma NFT contract
    /// @dev In production this should be a constant using the NFT's address to ensure security, we make it injectable now to ease testing
    address internal nftAddress;

    /// @notice Initializes the Vault contract and sets initial values
    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        endAt = 0;
        lastAddress = payable(0);
        endAtNft = 0;
        lastNftAddress = address(0);
    }

    /// @notice If someone would send ether without call data, we revert and tell them to use sendEther.
    receive() external payable {
        revert("Please use the sendEther function to participate in the reward pool.");
    }


    /// @notice Allows users to send Ether to the contract and participate in the Ether reward pool
    /// @dev If the countdown timer is active, it resets to 1 day after each deposit
    function sendEther() external payable {
        require(msg.value > 0, "Ether value must be more than 0.");
        if (endAt == 0) {
            endAt = block.timestamp + 1 days;
        }

        if (block.timestamp < endAt) {
            lastAddress = payable(msg.sender);
            endAt = block.timestamp + 1 days;
            emit EtherReceived(msg.sender, msg.value);
        }
    }

    /// @notice Allows the last person who sent Ether to claim all the Ether in the contract
    /// @dev Can only be called when the timer expires
    function claimEther() external {
        require(msg.sender == lastAddress, "Only the winner can claim the funds.");
        require(block.timestamp >= endAt, "The competition hasn't finished yet.");

        // Reentrancy protection, reset game state
        uint256 balance = address(this).balance;
        lastAddress = payable(0);
        endAt = 0;

        // Now transfer the Ether
        payable(msg.sender).transfer(balance);
        emit RewardPayedOut(msg.sender, balance, "Reward claimed, congratulations!");
    }

    /// @notice Allows users to send an NFT to the contract and participate in the NFT reward pool
    /// @param _nftId The ID of the NFT to deposit
    /// @dev Transfers the NFT to the contract and resets the countdown timer
    function sendNft(uint256 _nftId) external {
        require(ERC721(nftAddress).ownerOf(_nftId) == msg.sender, "You do not own this NFT");
        if (endAtNft == 0) {
            endAtNft = block.timestamp + 1 days;
        }

        if (block.timestamp < endAtNft) {
            ERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);
            endAtNft = block.timestamp + 1 days;
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

        // Reentrancy protection, reset game state
        address nftRecipient = lastNftAddress;
        lastNftAddress = address(0);
        endAtNft = 0;

        // Now transfer the NFTs
        for (uint256 i = 0; i < nftIds.length; i++) {
            ERC721(nftAddress).safeTransferFrom(address(this), nftRecipient, nftIds[i]);
        }

        // Reset the nftIds array
        delete nftIds;
        emit NftsRewarded(nftRecipient, "All NFTs claimed.");
    }
}