// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/ThreeSigmaNFT.sol";

contract VaultTest is Test {
    Vault vault;
    ThreeSigmaNFT nft;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this); // Test contract owner
        user1 = vm.addr(1);
        user2 = vm.addr(2);

        // Deploy NFT and Vault contracts
        nft = new ThreeSigmaNFT();
        vault = new Vault(address(nft));

        // Mint NFTs to users
        nft.mint(user1);
        nft.mint(user2);

        // Send Ether to the users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

/// @notice Test Ether deposit and event emission
function testSendEther() public {
    vm.prank(user1); // Set msg.sender as user1
    
    // Call the function that should emit the event
    vault.sendEther{value: 1 ether}();

    // Verify the Ether was received correctly and the contract state was updated
    assertEq(vault.lastAddress(), user1);            // Verify lastAddress was updated to user1
    assert(vault.endAt() > block.timestamp);         // Verify the timer is set correctly
}


    /// @notice Test Ether claim by the last depositor
    function testClaimEther() public {
        vm.prank(user1); 
        vault.sendEther{value: 1 ether}();

        // Fast forward time to simulate end of timer
        vm.warp(block.timestamp + 2 minutes);

        uint256 initialBalance = user1.balance;
        vm.prank(user1);
        vault.claimEther();

        assertEq(user1.balance, initialBalance + 1 ether); // Verify user1 claimed Ether

        // Verify contract state reset
        assertEq(vault.endAt(), 0);
        assertEq(vault.lastAddress(), address(0));
    }

    /// @notice Test that only the last Ether depositor can claim the funds
    function testCannotClaimEtherIfNotLastDepositor() public {
        vm.prank(user1);
        vault.sendEther{value: 1 ether}();

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user2);
        vm.expectRevert("Only the winner can claim the funds.");
        vault.claimEther();
    }

    /// @notice Test NFT deposit and event emission
    function testSendNft() public {
        vm.prank(user1);
        nft.approve(address(vault), 0); // Approve the vault to transfer the NFT
        vm.prank(user1);
        vault.sendNft(0);

        assertEq(vault.lastNftAddress(), user1); // Verify last NFT address
        assert(vault.endAtNft() > block.timestamp); // Check that timer is set
    }

    /// @notice Test NFT claim by the last depositor
    function testClaimNfts() public {
        vm.prank(user1);
        nft.approve(address(vault), 0); // Approve vault to transfer NFT
        vm.prank(user1);
        vault.sendNft(0);

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user1);
        vault.claimNfts();

        assertEq(nft.ownerOf(0), user1); // Verify NFT returned to user1

        // Verify contract state reset
        assertEq(vault.endAtNft(), 0);
        assertEq(vault.lastNftAddress(), address(0));
        
        vm.expectRevert();
        vault.nftIds(0);  // This should revert because the array is empty
    }

    /// @notice Test that only the last NFT depositor can claim the NFTs
    function testCannotClaimNftsIfNotLastDepositor() public {
        vm.prank(user1);
        nft.approve(address(vault), 0); // Approve vault to transfer NFT
        vm.prank(user1);
        vault.sendNft(0);

        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user2);
        vm.expectRevert("Only the last depositor can claim the NFTs");
        vault.claimNfts();
    }
}
