// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CustomString.sol";

contract FunkiVIPToken is ERC721, Ownable {
    using SafeMath for uint256;

    string public FVT_PROVENANCE = "";
    uint256 public currentSupply = 0;
    uint256 public totalSupply = 1000;
    uint256 public mintPrice = 0.1 ether;
    
    mapping (address=>uint256) private _tokenBalance;
    string baseTokenURI;
    uint256 public maxMintNumber = 10;
    bool public paused = false;

    struct FVT {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
    }
    mapping(uint256=>FVT) private fvts;

    event FVTMint(address indexed to, FVT _fvt);
    event SetPrice(uint256 _value);
    event ChangePaused(bool _value);
    
    constructor(string memory _baseTokenURI) ERC721("Funki VIP Token", "FVT") {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused() public onlyOwner {
        paused = !paused;
        emit ChangePaused(paused);
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit SetPrice(mintPrice);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function createTokenURI(uint256 tokenId) public view returns(string memory) {
        return CustomString.strConcat(baseTokenURI, CustomString.uint2str(tokenId));
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        FVT_PROVENANCE = provenanceHash;
    }

    function mintFVT(uint256 _numberOfTokens) public payable {
        require(!paused, "Minting is paused");
        require(_numberOfTokens == 1, "Too many tokens to mint at once.");
        require(currentSupply.add(_numberOfTokens) < totalSupply, "No fvt available for minting!");
        require(msg.value >= mintPrice.mul(_numberOfTokens), "Amount is not enough!");

        uint256 _index = currentSupply;
        currentSupply += _numberOfTokens;
        _tokenBalance[_msgSender()] += _numberOfTokens;
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            FVT storage newFVT = fvts[_index.add(i)];
            newFVT.tokenId = _index.add(i);
            newFVT.creator = _msgSender();
            newFVT.owner = _msgSender();
            newFVT.uri = createTokenURI(_index.add(i));
            _safeMint(_msgSender(), _index.add(i));
            emit FVTMint(_msgSender(), newFVT);
        }
    }
    
    function creatorOf(uint256 _tokenId) public view returns (address) {
        return fvts[_tokenId].creator;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < currentSupply, "ERC721Metadata: URI query for nonexistent token");
        return fvts[_tokenId].uri;
    }

    function withdrawAll() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = fvts[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check token index is available
        require(tokenId < currentSupply, "Undefined tokenID!");
        // check owner of token
        require(ownerOf(tokenId) == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        fvts[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        emit Transfer(from, to, tokenId);
    }
}