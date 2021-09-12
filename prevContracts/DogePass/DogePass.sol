// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CustomString.sol";

contract DogePass is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public currentASupply = 0;
    uint256 public currentBSupply = 0;
    uint256 public aSupply = 9000;
    uint256 public bSupply = 1000;
    uint256 public mintAPrice = 0.06 ether;
    uint256 public mintBPrice = 0.08 ether;
    uint256 public maxMintNumber = 10;
    string public baseTokenURI = "https://ipfs.dogepass.io/metadata/";
    
    bool public paused = true;
    bool public enableB = false;

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
    event EnabledTypeB(bool _value);
    event MaxMintNumber(uint256 _value);
    event SetAPrice(uint256 _value);
    event SetBPrice(uint256 _value);
    
    constructor() ERC721("DogePass", "DOPA") {

    }

    function totalSupply() public view returns(uint256) {
        return aSupply.add(bSupply);
    }

    function setBSupply(uint256 _bSupply) public onlyOwner {
        require(_bSupply > currentBSupply, "Invalid amound for Type B supply!");
        bSupply = _bSupply;
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function setMintAPrice(uint256 _mintAPrice) public onlyOwner {
        mintAPrice = _mintAPrice;
        emit SetAPrice(_mintAPrice);
    }

    function setMintBPrice(uint256 _mintBPrice) public onlyOwner {
        mintBPrice = _mintBPrice;
        emit SetBPrice(_mintBPrice);
    }

    function changeBState() public onlyOwner {
        enableB = !enableB;
        emit EnabledTypeB(enableB);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxMintNumber(uint256 _maxMintNumber) public onlyOwner {
        require(_maxMintNumber <= 20, "Too many tokens for one mint!");
        maxMintNumber = _maxMintNumber;
        emit MaxMintNumber(_maxMintNumber);
    }

    function currentSupply() public view returns(uint256) {
        return currentASupply.add(currentBSupply);
    }

    function createTokenURI(uint256 tokenId) public view returns(string memory) {
        return CustomString.strConcat(baseTokenURI, CustomString.uint2str(tokenId));
    }

    function mintPunk(uint256 _numberOfTokens) public payable {
        require(!paused, "Minting is paused");
        require(_numberOfTokens <= maxMintNumber, "Too many tokens for one mint!");
        if (enableB) {
            require(currentBSupply.add(_numberOfTokens) < bSupply, "No punks available for minting!");
            require(msg.value >= _numberOfTokens.mul(mintBPrice), "Amount is not enough!");

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                uint256 _punkIndex = aSupply.add(currentBSupply);
                currentBSupply += 1;
                _tokenBalance[_msgSender()] += 1;
                Punk storage newPunk = punks[_punkIndex];
                newPunk.tokenId = _punkIndex;
                newPunk.creator = _msgSender();
                newPunk.owner = _msgSender();
                newPunk.uri = createTokenURI(_punkIndex);
                newPunk.ownershipRecords.push(_msgSender());
                newPunk.tokenType = 2;
                _safeMint(_msgSender(), _punkIndex);
                emit PunkMint(_msgSender(), newPunk);
            }
        } else {
            require(currentASupply.add(_numberOfTokens) < aSupply, "No punks available for minting!");
            require(msg.value >= _numberOfTokens.mul(mintAPrice), "Amount is not enough!");

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                uint256 _punkIndex = currentASupply;
                currentASupply += 1;
                _tokenBalance[_msgSender()] += 1;
                Punk storage newPunk = punks[_punkIndex];
                newPunk.tokenId = _punkIndex;
                newPunk.creator = _msgSender();
                newPunk.owner = _msgSender();
                newPunk.uri = createTokenURI(_punkIndex);
                newPunk.ownershipRecords.push(_msgSender());
                newPunk.tokenType = 1;
                _safeMint(_msgSender(), _punkIndex);
                emit PunkMint(msg.sender, newPunk);
            }
            if (currentASupply >= aSupply && enableB == false) {
                enableB = !enableB;
            }
        }
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < currentASupply || (_tokenId >= currentASupply && _tokenId < aSupply.add(currentBSupply)),
            "ERC721Metadata: URI query for nonexistent token");
        return punks[_tokenId].uri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = punks[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId < currentASupply || (tokenId >= currentASupply && tokenId < aSupply.add(currentBSupply)), "Undefined tokenID!");
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
}
