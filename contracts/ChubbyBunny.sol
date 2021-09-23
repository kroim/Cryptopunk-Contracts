// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CustomString.sol";

contract ChubbyBunny is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public currentSupply = 0;
    uint256 public season1 = 10000;
    uint256 public season2 = 10000;
    uint256 public mintPrice = 0.05 ether;
    uint256 public seasonState = 1;
    uint256 public devFee = 15;  // 1.5% with 1000 unit
    uint256 public devBalance = 0;
    address public devWallet = 0x5eacBb8267458B6bAC84D4019Bb64CC1a35b248E;
    string public baseTokenURI = "https://ipfs.domain.com/metadata/";
    bool public paused = false;
    mapping (address=>uint256) private _tokenBalance;
    
    struct Punk {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
    }
    mapping(uint256=>Punk) private punks;

    event PunkMint(address indexed to, Punk _punk);
    event SetPrice(uint256 _value);
    
    constructor() ERC721("Chubby Bunny", "CUBU") {}

    function totalSupply() public view returns(uint256) {
        return currentSupply;
    }

    function changePaused() public onlyOwner {
        paused = !paused;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit SetPrice(_mintPrice);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function createTokenURI(uint256 tokenId) public view returns(string memory) {
        return CustomString.strConcat(baseTokenURI, CustomString.uint2str(tokenId));
    }

    function mintPunk() public payable {
        require(!paused, "Minting is paused");
        if (seasonState == 1) {
            require(currentSupply.add(1) <= season1, "No punks available for minting!");
        } else {
            require(currentSupply.add(1) <= season1.add(season2), "No punks available for minting!");
        }
        require(msg.value >= mintPrice, "Amount is not enough!");
        devBalance += msg.value.mul(devFee).div(1000);
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
        if (seasonState == 1 && currentSupply > season1) {
            seasonState = 2;
            devFee = 30;
        }
        emit PunkMint(_msgSender(), newPunk);
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < currentSupply, "ERC721Metadata: URI query for nonexistent token");
        return punks[_tokenId].uri;
    }

    function withdrawByOwner() public {
        require(_msgSender() == owner(), "You are not Owner!");
        payable(_msgSender()).transfer(address(this).balance.sub(devBalance));
    }

    function withdrawByDev() public {
        require(_msgSender() == devWallet, "You are not a DEV!");
        payable(_msgSender()).transfer(devBalance);
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
        require(ownerOf(tokenId) == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        punks[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        punks[tokenId].ownershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }
}
