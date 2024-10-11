// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;
    function transferFrom(address, address, uint256) external;
}

contract Vault {
    event EtherReceived(address indexed sender, uint256 amount);
    event RewardPayedOut(address indexed sender, uint256 amount, string reason);

    uint256 public endAt;
    address payable public lastAddress;

    constructor() {
        endAt = 0;
    }

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

    function claimEther() external payable {
        require(msg.sender == lastAddress, "Only the winner can claim the funds.");
        require(block.timestamp >= endAt, "The competition hasn't finished yet.");

        // Transfer the remaining balance to the last address, and reset the game
        emit RewardPayedOut(msg.sender, address(this).balance, "Reward claimed, congratulations!");
        lastAddress.transfer(address(this).balance);
        endAt = 0;
    }
}