// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract WonderPunks is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _punkIDs;
    uint256 public totalSupply = 11000;

    constructor() ERC721("WonderPunks", "WDP") {
        
    }
    
}