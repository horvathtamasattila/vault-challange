// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title ThreeSigmaNFT
/// @notice Implements ERC721 standard for creating NFTs that can be bought, sold, and transferred
contract ThreeSigmaNFT is ERC721, Ownable {
    /// @notice The next available token ID for minting
    uint256 public nextTokenId;

    /// @notice Initializes the ERC721 token with a name and symbol
    constructor() ERC721("ThreeSigmaNFT", "ThreeSigmaNFT") {}

    /// @notice Allows the contract owner to mint new NFTs
    /// @param to The address to mint the NFT to
    function mint(address to) external onlyOwner {
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
}