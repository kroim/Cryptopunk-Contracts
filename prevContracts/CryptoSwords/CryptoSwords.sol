// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CustomString.sol";

contract CryptoSwords is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply = 7777;
    uint256 public currentSupply = 0;
    uint256 public price = 0.05 ether;
    uint256 public maxMintNumber = 10;
    bool public paused = false;
    uint256 public _tokenIndex = 0;
    string public baseTokenURI = "https://ipfs.crypto-swords.com/metadata/";
    
    struct Punk {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
    }
    mapping(uint256=>Punk) private punks;
    mapping (address=>uint256) private _tokenBalance;

    event PunkMint(address indexed to, Punk _punk);
    event MaxMintNumber(uint256 _value);
    event SetPrice(uint256 _value);
    event ChangePaused(bool _value);

    constructor() ERC721("Crypto Swords", "Swords") {}

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function changePaused() public onlyOwner {
        paused = !paused;
        emit ChangePaused(paused);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit SetPrice(_price);
    }

    function setMaxMintNumber(uint256 _maxMintNumber) public onlyOwner {
        require(_maxMintNumber <= 20, "Too many tokens for one mint!");
        maxMintNumber = _maxMintNumber;
        emit MaxMintNumber(_maxMintNumber);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function createTokenURI(uint256 tokenId) public view returns(string memory) {
        return CustomString.strConcat(baseTokenURI, CustomString.uint2str(tokenId));
    }

    function mintPunk(uint256 _numberOfTokens) public payable {
        require(!paused, "Minting is paused");
        require(_numberOfTokens <= maxMintNumber, "Too many tokens for one mint!");
        require(currentSupply.add(_numberOfTokens) <= totalSupply, "No punks available for minting!");
        require(msg.value >= _numberOfTokens.mul(price), "Amount is not enough!");
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 _punkIndex = currentSupply;
            currentSupply += 1;
            _tokenBalance[_msgSender()] += 1;
            Punk storage newPunk = punks[_punkIndex];
            newPunk.tokenId = _punkIndex;
            newPunk.creator = _msgSender();
            newPunk.owner = _msgSender();
            newPunk.uri = createTokenURI(_punkIndex);
            newPunk.ownershipRecords.push(_msgSender());
            _safeMint(_msgSender(), _punkIndex);
            emit PunkMint(_msgSender(), newPunk);
        }
    }

    receive() external payable {}

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < currentSupply, "ERC721Metadata: URI query for nonexistent token");
        return punks[_tokenId].uri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = punks[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId < currentSupply, "Undefined tokenID!");
        // check owner of punk
        require(punks[tokenId].owner == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        punks[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        punks[tokenId].ownershipRecords.push(to);
        
        emit Transfer(from, to, tokenId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
