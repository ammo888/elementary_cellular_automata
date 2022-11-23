// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/common/ERC2981.sol";


contract ElementaryCellularAutomaton is ERC721URIStorage, ERC2981
{
    // Base price = 0.01 Ether
    uint public constant BASE_PRICE = 10000000 gwei;
    // Royalty = 2.5%
    uint96 public constant ROYALTY = 250;

    // Data URI header
    bytes constant PREFIX = "data:text/plain;charset=utf-8,";

    // Dead and Alive ASCII codes
    bytes1 constant DEAD = 0x2E; // '.'
    bytes1 constant ALIVE = 0x2B; // '+'

    address _owner;

    // Contract is an ERC-721 (NFT) and ERC-2981 (NFT Royalty Standard)
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("ElementaryCellularAutomaton", "ECA")
    {
        _owner = msg.sender;
        _setDefaultRoyalty(_owner, ROYALTY);
    }

    function salePrice(uint8 sizeType) public pure returns (uint)
    {
        // Sale price scales quadratically with the size type
        return BASE_PRICE * sizeType * sizeType;
    }
    
    function createCellularAutomaton(uint8 rule, uint state, uint8 sizeType) public payable returns (uint)
    {
        uint price = salePrice(sizeType);
        require(msg.value >= price, string.concat("Not enough value sent - must be at least ", Strings.toString(price)));
        require(sizeType >= 1, "Size type must be no smaller than 1");
        require(sizeType <= 5, "Size type must be no larger than 5");

        // Size of grid is 2^(sizeType) - 1
        uint sideSize = (1 << sizeType) - 1;
        // Mask of all 1's to determine initial state
        uint stateMask = (1 << sideSize) - 1;
        // Masked state
        uint actualState = state & stateMask;
        // Create token ID based on rule, actual state, size type
        uint tokenID = constructTokenID(rule, actualState, sizeType);

        // Mint token
        _safeMint(msg.sender, tokenID);
        // Calculate image data and save token URI
        _setTokenURI(tokenID, draw(rule, actualState, sideSize));
        // Send ether payment to owner of this NFT collection
        (bool sent, bytes memory data) = _owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        return tokenID;
    }

    function constructTokenID(uint8 rule, uint state, uint8 sizeType) internal pure returns (uint)
    {
        // Token ID
        // [              32              ][    8    ][    8    ]
        // [             STATE            ][   RULE  ][SIZE TYPE]
        uint tokenID = state;
        tokenID <<= 8;
        tokenID |= rule;
        tokenID <<= 8;
        tokenID |= sizeType;
        return tokenID;
    }

    function draw(uint8 rule, uint state, uint sideSize) internal pure returns (string memory)
    {
        // Create output buffer, accounting for data URI prefix and end of line characters
        bytes memory output = new bytes((sideSize * (sideSize + 3)) + PREFIX.length);

        // Insert prefix
        uint index;
        for (index = 0; index < PREFIX.length; index++) 
        {
            output[index] = PREFIX[index];
        }

        uint row;
        uint col;

        // Initial state
        uint previousStateStartIndex = index;

        // Copy over initial state into output
        for (col = 0; col < sideSize; col++)
        {
            output[index++] = (state & (1 << col)) != 0 ? ALIVE : DEAD;
        }
        output[index++] = 0x25;
        output[index++] = 0x30;
        output[index++] = 0x41;

        // Calculate next generations
        for (row = 1; row < sideSize; row++)
        {
            uint currentStateStartIndex = index;
            for (col = 0; col < sideSize; col++)
            {
                // Indices of neighbors, taking into account left-to-right wrapping
                uint leftIndex = col == 0 ? sideSize - 1 : col - 1;
                uint rightIndex = col == (sideSize - 1) ? 0 : col + 1;

                // Calculate rule mask based on neighbors and current state
                uint ruleMask = output[previousStateStartIndex + leftIndex] == ALIVE ? 1 : 0;
                ruleMask <<= 1;
                ruleMask += output[previousStateStartIndex + col] == ALIVE ? 1 : 0;
                ruleMask <<= 1;
                ruleMask += output[previousStateStartIndex + rightIndex] == ALIVE ? 1 : 0;

                // Use rule mask on the rule to determine whether nexte generation is alive or dead
                output[index++] = (rule & (1 << ruleMask) != 0) ? ALIVE : DEAD; 
            }
            output[index++] = 0x25;
            output[index++] = 0x30;
            output[index++] = 0x41;
            previousStateStartIndex = currentStateStartIndex;
        }

        return string(output);
    }
}