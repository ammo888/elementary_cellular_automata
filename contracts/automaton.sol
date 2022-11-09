// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract ElementaryCellularAutomaton is ERC721URIStorage
{
    uint public constant BASE_PRICE = 10000000 gwei;
    bytes1 constant DEAD = 0x2E; // '.'
    bytes1 constant ALIVE = 0x2B; // '+'

    bytes constant PREFIX = "data:text/plain;charset=utf-8,";
    address _owner;

    constructor() ERC721("ElementaryCellularAutomaton", "ECA")
    {
        _owner = msg.sender;
    }

    function salePrice(uint8 sizeType) public pure returns (uint)
    {
        return BASE_PRICE * sizeType * sizeType;
    }
    
    function createCellularAutomaton(uint8 rule, uint state, uint8 sizeType) public payable returns (uint)
    {
        uint price = salePrice(sizeType);
        require(msg.value >= price, string.concat("Not enough value sent - must be at least ", Strings.toString(price)));
        require(sizeType >= 1, "Size type must be no smaller than 1");
        require(sizeType <= 5, "Size type must be no larger than 5");

        uint sideSize = (1 << sizeType) - 1;
        uint stateMask = (1 << sideSize) - 1;
        uint actualState = state & stateMask;

        uint tokenID = constructTokenID(rule, actualState, sizeType);

        _safeMint(msg.sender, tokenID);
        _setTokenURI(tokenID, draw(rule, actualState, sideSize));
        return tokenID;
    }

    function constructTokenID(uint8 rule, uint state, uint8 sizeType) internal pure returns (uint)
    {
        uint tokenID = state;
        tokenID <<= 8;
        tokenID |= rule;
        tokenID <<= 8;
        tokenID |= sizeType;
        return tokenID;
    }

    function draw(uint8 rule, uint state, uint sideSize) internal pure returns (string memory)
    {
        bytes memory output = new bytes((sideSize * (sideSize + 3)) + PREFIX.length);

        uint index;
        for (index = 0; index < PREFIX.length; index++) 
        {
            output[index] = PREFIX[index];
        }

        uint row;
        uint col;

        // Initial state
        uint previousStateStartIndex = index;

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
                uint leftIndex = col == 0 ? sideSize : col - 1;
                uint rightIndex = col == sideSize ? 0 : col + 1;

                uint ruleMask = output[previousStateStartIndex + leftIndex] == ALIVE ? 1 : 0;
                ruleMask <<= 1;
                ruleMask += output[previousStateStartIndex + col] == ALIVE ? 1 : 0;
                ruleMask <<= 1;
                ruleMask += output[previousStateStartIndex + rightIndex] == ALIVE ? 1 : 0;

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