// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoSwords is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply = 7777;
    uint256 public currentSupply = 0;
    uint256 public price = 0.05 ether;
    uint256 public paused = 0;  // 0: paused, 1: mintable
    uint256 public _tokenIndex = 0;

    struct Item {
        address itemCreator;
        address itemOwner;
        string itemUri;
        uint256 itemId;
        address[] ownerRecords;
    }

    mapping(uint256=>Item) public items;
    mapping(address=>uint256) private _balanceOf;

    event MintItem(address indexed to, Item item);

    constructor() ERC721("Crypto Swords", "Swords") {
        _balanceOf[msg.sender] = 7777;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balanceOf[account];
    }

    function setPaused(uint256 _paused) public onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return items[tokenId].itemUri;
    }

    function mintItem(string[] memory _uris) public payable {
        require(paused == 1, "Minting is paused!");
        uint256 numbers = _uris.length;
        require(currentSupply + numbers <= totalSupply, "No items available for minting!");
        require(msg.value >= price.mul(numbers), "Insufficent balance!");
        currentSupply += numbers;
        _balanceOf[owner()] -= numbers;
        _balanceOf[msg.sender] += numbers;
        for (uint256 i = 0; i < numbers; i++) {
            Item storage newItem = items[_tokenIndex];
            newItem.itemCreator = msg.sender;
            newItem.itemOwner = msg.sender;
            newItem.itemUri = _uris[i];
            newItem.ownerRecords.push(msg.sender);
            emit MintItem(msg.sender, newItem);
        }
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
