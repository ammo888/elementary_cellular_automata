// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/common/ERC2981.sol";


contract BigECA is ERC721URIStorage, ERC2981
{
    uint public constant BASE_PRICE = 1 ether;
    uint96 public constant ROYALTY = 250;
    uint16 constant SIZE = 256;

    bytes constant PREFIX = "data:text/plain;charset=utf-8,";
    bytes1 constant DEAD = 0x2E; // '.'
    bytes1 constant ALIVE = 0x2B; // '+'

    uint nextTokenId = 1;

    address _owner;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("BigECA", "BECA")
    {
        _owner = msg.sender;
        _setDefaultRoyalty(_owner, ROYALTY);
    }

    function createCellularAutomaton(uint8 rule, uint state) public payable returns (uint)
    {
        require(msg.value >= BASE_PRICE, "Not enough value sent - must be at least 1 ether");

        uint tokenID = nextTokenId++;
        _safeMint(msg.sender, tokenID);
        _setTokenURI(tokenID, draw(rule, state));
        (bool sent, bytes memory data) = _owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        return tokenID;
    }

    function live(uint8 rule, uint8 currentState) internal pure returns (bool)
    {
        // rule
        //100101010011010111011011...
        //aaaabbbbccccddddeeeeffff...
        return true;
    }

    function draw(uint8 rule, uint state) internal pure returns (string memory)
    {

        uint[256] memory grid;
        grid[0] = state;

        uint rowIndex;
        uint colIndex;
        for (rowIndex = 1; rowIndex < SIZE; rowIndex++)
        {
            uint prevRow = grid[rowIndex - 1];
            uint row = 0;

            // optimization for last 2
            for (colIndex = 0; colIndex < SIZE - 2; colIndex++)
            {
                uint window = (7 & (prevRow >> colIndex));
                row |= (rule & 1 << window) >> window << colIndex;
            }
        }

        bytes memory output = new bytes(PREFIX.length + (SIZE * (SIZE + 3)));

        return string(output);
    }
}
