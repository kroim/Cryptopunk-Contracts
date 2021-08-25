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
    uint256 public mintPrice = 0.1 ether;
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

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function initializeHash(string[] memory _hashes) public onlyOwner {
        for (uint256 i = 0; i < _hashes.length; i++) {
            hashes[i] = _hashes[i];
        }
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function currentSupply() public view returns(uint256) {
        return _fufoIDs.current();
    }

    function mintPunk() public payable {
        require(!paused, "Minting is paused");
        require(currentSupply() < totalSupply, "No punks available for minting!");
        require(_tokenBalance[owner()] > 0, "No punks available for minting from owner issue!");
        if (_msgSender() != owner()) {
            require(msg.value >= mintPrice, "Insufficient Balance!");
        }
        uint256 _punkIndex = _fufoIDs.current();
        _fufoIDs.increment();
        _tokenBalance[owner()] -= 1;
        _tokenBalance[_msgSender()] += 1;
        Punk storage newPunk = punks[_punkIndex];
        newPunk.tokenId = _punkIndex;
        newPunk.creator = _msgSender();
        newPunk.owner = _msgSender();
        newPunk.uri = hashes[_punkIndex];
        newPunk.ownershipRecords.push(_msgSender());
        emit PunkMint(msg.sender, newPunk);
    }
    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < _fufoIDs.current(), "ERC721Metadata: URI query for nonexistent token");
        return punks[tokenId].uri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = punks[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId < _fufoIDs.current(), "Undefined punk index!");
        // check owner of punk
        require(punks[tokenId].owner == from, "Caller is not owner");
        punks[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        punks[tokenId].ownershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }
}
