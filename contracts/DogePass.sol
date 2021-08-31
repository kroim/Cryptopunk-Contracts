// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DogePass is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public currentASupply = 0;
    uint256 public currentBSupply = 9000;
    uint256 public aSupply = 9000;
    uint256 public bSupply = 1000;
    uint256 public mintAPrice = 0.06 ether;
    uint256 public mintBPrice = 0.08 ether;
    string private _uriA;
    string private _uriB;
    uint256 public maxMintNumber = 10;
    
    bool public paused = true;
    bool public enableB = false;

    string private _baseTokenURI;

    mapping (address=>uint256) private _tokenBalance;
    
    
    struct Punk {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
        uint256 tokenType;  // 1: Type A, 2: Type B
    }
    mapping(uint256=>Punk) private punks;

    event PunkMint(address indexed to, Punk _punk);
    
    constructor() ERC721("DogePass", "DOPA") {}

    function totalSupply() public view returns(uint256) {
        return aSupply.add(bSupply);
    }

    function setASupply(uint256 _aSupply) public onlyOwner {
        require(_aSupply <= 9000 && _aSupply > currentASupply, "Invalid amound for Type A supply!");
        aSupply = _aSupply;
    }

    function setBSupply(uint256 _bSupply) public onlyOwner {
        require(_bSupply > currentBSupply, "Invalid amound for Type A supply!");
        bSupply = _bSupply;
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function setMintAPrice(uint256 _mintAPrice) public onlyOwner {
        mintAPrice = _mintAPrice;
    }

    function setMintBPrice(uint256 _mintBPrice) public onlyOwner {
        mintBPrice = _mintBPrice;
    }

    function changeBState() public onlyOwner {
        enableB = !enableB;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setURIA(string memory _typeAURI) public onlyOwner {
        _uriA = _typeAURI;
    }

    function setURIB(string memory _typeBURI) public onlyOwner {
        _uriB = _typeBURI;
    }

    function setMaxMintNumber(uint256 _maxMintNumber) public onlyOwner {
        maxMintNumber = _maxMintNumber;
    }

    function currentSupply() public view returns(uint256) {
        return currentASupply.add(currentBSupply);
    }

    function mintPunk() public payable {
        require(!paused, "Minting is paused");
        if (enableB) {
            require(currentBSupply < bSupply, "No punks available for minting!");
            uint256 _punkIndex = currentBSupply;
            currentBSupply++;
            _tokenBalance[_msgSender()] += 1;
            Punk storage newPunk = punks[_punkIndex];
            newPunk.tokenId = _punkIndex;
            newPunk.creator = _msgSender();
            newPunk.owner = _msgSender();
            newPunk.uri = _uriB;
            newPunk.ownershipRecords.push(_msgSender());
            newPunk.tokenType = 2;
            emit PunkMint(msg.sender, newPunk);
        } else {
            require(currentASupply < aSupply, "No punks available for minting!");
            uint256 _punkIndex = currentASupply;
            currentASupply++;
            _tokenBalance[_msgSender()] += 1;
            Punk storage newPunk = punks[_punkIndex];
            newPunk.tokenId = _punkIndex;
            newPunk.creator = _msgSender();
            newPunk.owner = _msgSender();
            newPunk.uri = _uriA;
            newPunk.ownershipRecords.push(_msgSender());
            newPunk.tokenType = 1;
            if (currentASupply == aSupply && !enableB) {
                enableB = !enableB;
            }
            emit PunkMint(msg.sender, newPunk);
        }
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < currentASupply || tokenId < currentBSupply,
            "ERC721Metadata: URI query for nonexistent token");
        return punks[tokenId].uri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = punks[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId < currentASupply || tokenId < currentBSupply, "Undefined tokenID!");
        // check owner of punk
        require(punks[tokenId].owner == from, "Caller is not owner");
        punks[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        punks[tokenId].ownershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }
}
