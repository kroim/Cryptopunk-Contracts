/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FunkiFoxes is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _fufoIDs;
    uint256 public totalSupply = 12000;
    uint256 public currentSupply = 0;
    uint256 public price = 0.1 ether;
    bool public paused = true;
    mapping (address=>uint256) private _tokenBalance;
    mapping(uint256=>string) private hashes;
    
    struct Punk {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
    }
    mapping(uint256=>Punk) private punks;

    event PunkMint(address indexed to, Punk _punk);
    
    constructor() ERC721("FunkiFoxes", "FUFO") {
        _tokenBalance[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _tokenBalance[account];
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return punks[_tokenId].uri;
    }

    function initializeHash(string[] memory _hashes) public onlyOwner {
        
    }
}
