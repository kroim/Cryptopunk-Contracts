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
import "@openzeppelin/contracts/utils/Counters.sol";
import "./lib/CustomString.sol";

contract FunkiFoxes is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _fufoIDs;
    uint256 public totalSupply = 12000;
    uint256 public mintPrice = 0.1 ether;
    bool public paused = true;
    mapping (address=>uint256) private _tokenBalance;
    bool public hashFlag = true;
    mapping(uint256=>string) private hashes;
    
    struct Fox {
        uint256 tokenId;
        address creator;
        address owner;
        string uri;
        address[] ownershipRecords;
    }
    mapping(uint256=>Fox) private foxes;

    event FoxMint(address indexed to, Fox _fox);
    
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

    function setHashFlag() public onlyOwner {
        hashFlag = !hashFlag;
    }

    function checkHash(uint256 hashId) public view returns(string memory) {
        require(hashFlag, "Unable to check hash!");
        return hashes[hashId];
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function currentSupply() public view returns(uint256) {
        return _fufoIDs.current();
    }

    function mintFox() public payable {
        require(!paused, "Minting is paused");
        require(currentSupply() < totalSupply, "No foxes available for minting!");
        require(_tokenBalance[owner()] > 0, "No foxes available for minting from owner issue!");
        if (_msgSender() != owner()) {
            require(msg.value >= mintPrice, "Insufficient Balance!");
        }
        uint256 _foxIndex = _fufoIDs.current();
        _fufoIDs.increment();
        _tokenBalance[owner()] -= 1;
        _tokenBalance[_msgSender()] += 1;
        Fox storage newFox = foxes[_foxIndex];
        newFox.tokenId = _foxIndex;
        newFox.creator = _msgSender();
        newFox.owner = _msgSender();
        newFox.uri = hashes[_foxIndex];
        newFox.ownershipRecords.push(_msgSender());
        emit FoxMint(msg.sender, newFox);
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < _fufoIDs.current(), "ERC721Metadata: URI query for nonexistent token");
        return foxes[tokenId].uri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = foxes[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check fox index is available
        require(tokenId < _fufoIDs.current(), "Undefined fox index!");
        // check owner of fox
        require(foxes[tokenId].owner == from, "Caller is not owner");
        foxes[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        foxes[tokenId].ownershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }
}
