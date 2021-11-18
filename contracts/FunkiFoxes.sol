/**
                                   
                  .mhhhhsyhmd/     ````` ```hmNNMMdyoydy                        
                  :mhosyhyo+yho/::+dNdhshdhydmNmhsoooodm                        
                  /NNsssshmy///ossyyo+++hhdhhddhsooooomm                        
                  /NNdsssyN+/::///:::///+//////+shhyohMm                        
                  .+++dyyds/:::::::::::///////////+ohNMm                        
                  ````:md+::::::::::::://////////////oNNy                       
                      :N+/::::::/++ooo+///////+ssssssosMN::                     
                      /m///:::/sssssssso/////oosyhdhdhssNmd                     
                      -do//////oyhmdhmhho////oohyhysysy/shd.``                  
                      .od+/////odsysoo+o+//////+++++//++osddy/                  
                      -+m+////++oosssssssssssoooyhddhds:::hNMs                  
                      .sh++osyo+/:-....`````.:/mdyyyhms../dmmh                  
              `+++++++sNdmdh/......`````       -ydddh/o+/dh---                  
              .MMMMMMMmo/omdssh:--..```.-::::::/+syo//+sNN+                     
              .MMMMMMh////+//odsssso/-..`..---...```.-oMm`                      
              .MMMMMs///////////////osss+-:+++//+oo/dNMMm                       
              .MMMNo////////////////////+hs++++o+/ysyMMMm                       
              .MMN+//////////////////////////////////NMMm                       
              .MN////////////////////////////////////yMMm                       
              .Mo////////////////////////////////////+MMm                       
            :NNh//////////////////////////////////////NMm                       
            :MM+//////////////////////////////////////dMMhy                     
            :Mh///////////////////////////////////////hMMMm                     
            :Mo///////////////////////////////////////hMMMm                     
            :M////////////////////////////////////////dMMMm                     
            :M////////////////////////////////////////mMMMm                     
            :N//////////////////////////////+osyyysssshdNMN:-                   
            :M///////oo+/////////////+osyyhmh+:--......-ymMMNddds               
            :M+///////oyyhyyyyyyyyyhyyso++yd-...........:/ohmMMMh               
            :Ms////////////++++++//////+ohy-................:+dMh               
            :Mm/////////////////////+syyo:....................-dh               
            :MMs//////////////////ydy+:-----:/:...............-dh               
            -mNNo/////////////////+oyyyyyyyhNy-............-:smMh               
              :MNy///////////////////////+yh+...........-:oyNMMMh               
              .oodNy+////////////////+oshy/.............-::hNooo/               
                 yMMNds+/////////+dmys+:-..............-/smNd                   
                 yMMMMMMmhyo+//////shhs/----------:/oyhNMMm                     
                 ommmmmmmmmmmdhhyyyyyhmmddddhhhhddmmmmmmmmh                     
                                                                  
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CustomString.sol";

contract FunkiFoxes is ERC721, Ownable {
    using SafeMath for uint256;

    string public FOX_PROVENANCE = "";
    uint256 public currentSupply = 0;
    uint256 public totalSupply = 12000;
    uint256 public mintPrice = 0.1 ether;
    
    mapping (address=>uint256) private _tokenBalance;
    string baseTokenURI;
    uint256 public maxMintNumber = 10;
    bool public paused = true;

    struct Fox {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
    }
    mapping(uint256=>Fox) private foxes;

    bool public vipState = true;
    address public vipAddress;
    uint256 public vPrice = 0.05 ether;

    event FoxMint(address indexed to, Fox _fox);
    event SetPrice(uint256 _value);
    event ChangePaused(bool _value);
    event ChangeVIPState(bool _value);
    event SetVPrice(uint256 _value);
    
    constructor(string memory _baseTokenURI) ERC721("FunkiFoxes", "FUFO") {
        // https://ipfs.funkifoxes.com/token-metadata/
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
        FOX_PROVENANCE = provenanceHash;
    }

    function setVIPAddress(address _vipAddress) external onlyOwner {
        vipAddress = _vipAddress;
    }

    function setVIPState() external onlyOwner {
        vipState = !vipState;
        emit ChangeVIPState(vipState);
    }

    function setVIPPrice(uint256 _vPrice) external onlyOwner {
        vPrice = _vPrice;
        emit SetVPrice(vPrice);
    }

    function mintFox(uint256 _numberOfTokens) public payable {
        require(_numberOfTokens < maxMintNumber, "Too many tokens to mint at once");
        require(currentSupply.add(_numberOfTokens) < totalSupply, "No foxes available for minting!");
        if (vipState) {
            require(ERC721(vipAddress).balanceOf(_msgSender()) > 0, "Non VIP member");
            require(_tokenBalance[_msgSender()].add(_numberOfTokens) <= 2, "You can not mint more than 2 nfts!");
            require(msg.value >= vPrice.mul(_numberOfTokens), "Amount is not enough!");
        } else {
            require(!paused, "Minting is paused");
            require(msg.value >= mintPrice.mul(_numberOfTokens), "Amount is not enough!");
        }
        uint256 _foxIndex = currentSupply;
        currentSupply += _numberOfTokens;
        _tokenBalance[_msgSender()] += _numberOfTokens;
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            Fox storage newFox = foxes[_foxIndex.add(i)];
            newFox.tokenId = _foxIndex.add(i);
            newFox.creator = _msgSender();
            newFox.owner = _msgSender();
            newFox.uri = createTokenURI(_foxIndex.add(i));
            newFox.ownershipRecords.push(_msgSender());
            _safeMint(_msgSender(), _foxIndex.add(i));
            emit FoxMint(_msgSender(), newFox);
        }
    }
    
    function creatorOf(uint256 _tokenId) public view returns (address) {
        return foxes[_tokenId].creator;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < currentSupply, "ERC721Metadata: URI query for nonexistent token");
        return foxes[_tokenId].uri;
    }

    function withdrawAll() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = foxes[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check fox index is available
        require(tokenId < currentSupply, "Undefined tokenID!");
        // check owner of fox
        require(ownerOf(tokenId) == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        foxes[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        foxes[tokenId].ownershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }
}
