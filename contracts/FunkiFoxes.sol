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

 /**
  * Some got a head, but the cap don't fit.
  * Some got no head, but they got a cap.
  * Some got no cap, but they got the head.
  * Who the cap fits, better wear it.
  */

 /**
  * website:   https://funkifoxes.com
  * discord:   https://discord.gg/RmnteYEZ5h
  * twitter:   https://twitter.com/FunkiFoxes
  * instagram: https://instagram.com/funkifoxes
  * medium:    https://funkifoxes.medium.com  
  */
  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FunkiFoxes is Ownable, ERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint256;

    string public FOX_PROVENANCE = "";
    uint256 public maxTokenSupply = 12000;
    uint256 public mintPrice = 0.1 ether;
    
    mapping (address=>uint256) private _tokenBalance;
    string baseTokenURI;
    uint256 public maxMintNumber = 20;
    bool public paused = true;

    struct Fox {
        uint256 tokenId;
        address creator;
        address owner;
    }
    mapping(uint256=>Fox) private foxes;

    bool public fvtState = true;
    address public fvtAddress;
    uint256 public fvtPrice = 0.1 ether;
    uint256[12000] private _availableTokens;
    uint256 private _numAvailableTokens = 12000;

    event FoxMint(address indexed to, Fox _fox);
    event SetPrice(uint256 _value);
    event MaxMintNumber(uint256 _value);
    event ChangePaused(bool _value);
    event ChangeFVTState(bool _value);
    event SetFVTPrice(uint256 _value);
    
    constructor(string memory _baseTokenURI) ERC721("Funki Foxes", "FUFO") {
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

    function setMaxMintNumber(uint256 _maxMintNumber) public onlyOwner {
        maxMintNumber = _maxMintNumber;
        emit MaxMintNumber(_maxMintNumber);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        FOX_PROVENANCE = provenanceHash;
    }

    function setFVTAddress(address _fvtAddress) external onlyOwner {
        fvtAddress = _fvtAddress;
    }

    function setFVTState() external onlyOwner {
        fvtState = !fvtState;
        emit ChangeFVTState(fvtState);
    }

    function setFVTPrice(uint256 _fvtPrice) external onlyOwner {
        fvtPrice = _fvtPrice;
        emit SetFVTPrice(fvtPrice);
    }

    function mintReserves(uint256[] memory ids) public onlyOwner {
        require(ids.length <= maxMintNumber, "Too many tokens");
        require(validateReserveTokens(ids), "Invalid tokens to reserve!");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 _mintIndex = useAvailableTokenAtIndex(ids[i]);
            Fox storage newFox = foxes[_mintIndex];
            newFox.tokenId = _mintIndex;
            newFox.creator = _msgSender();
            newFox.owner = _msgSender();
            _safeMint(_msgSender(), _mintIndex);
            emit FoxMint(_msgSender(), newFox);
        }
    }

    function validateReserveTokens(uint256[] memory ids) internal view returns(bool) {
        bool res = true;
        for (uint256 i = 0; i < ids.length; i++) {
            if (_availableTokens[ids[i]] != 0) {
                res = false;
                break;
            }
        }
        return res;
    }

    function mintFox(uint256 _numberOfTokens) public payable {
        require(_numberOfTokens >= 1, "At least, one token should be");
        require(_numberOfTokens <= maxMintNumber, "Too many tokens to mint at once");
        uint256 totalSupply = totalSupply();
        require(totalSupply.add(_numberOfTokens) <= maxTokenSupply, "No foxes available for minting!");

        if (fvtState) {
            require(ERC721(fvtAddress).balanceOf(_msgSender()) > 0, "Non FVT member");
            require(_tokenBalance[_msgSender()].add(_numberOfTokens) <= 2, "You can not mint more than 2 tokens!");
            require(msg.value >= fvtPrice.mul(_numberOfTokens), "Amount is not enough!");
        } else {
            require(!paused, "Minting is paused");
            require(msg.value >= mintPrice.mul(_numberOfTokens), "Amount is not enough!");
        }
        _tokenBalance[_msgSender()] += _numberOfTokens;
        for (uint256 i = 1; i <= _numberOfTokens; i++) {
            uint256 _mintIndex = useRandomAvailableToken(_numberOfTokens, i);
            Fox storage newFox = foxes[_mintIndex];
            newFox.tokenId = _mintIndex;
            newFox.creator = _msgSender();
            newFox.owner = _msgSender();
            _safeMint(_msgSender(), _mintIndex);
            emit FoxMint(_msgSender(), newFox);
        }
    }

    function useRandomAvailableToken(uint256 _numToFetch, uint256 _i) internal returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    _numToFetch,
                    _i
                )
            )
        );
        uint256 randomIndex = (randomNum % _numAvailableTokens) + 1;
        return useAvailableTokenAtIndex(randomIndex);
    }
    
    function useAvailableTokenAtIndex(uint256 indexToUse) internal returns (uint256) {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }
        uint256 lastIndex = _numAvailableTokens - 1;
        if (indexToUse != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        _numAvailableTokens--;
        return result;
    }

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return foxes[_tokenId].creator;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _tokenBalance[account];
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_availableTokens[_tokenId] != 0, "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = Strings.toString(_tokenId);
        return string(abi.encodePacked(baseTokenURI, _tokenURI));
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
        // check owner of fox
        require(ownerOf(tokenId) == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        foxes[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;

        emit Transfer(from, to, tokenId);
    }
}


/**
 * Riddles?
 * What is the end of everything?
 * What kind of room has no doors or windows?
 * Which word in the dictionary is always spelled incorrectly?
 *
 * There are 4 riddles in this contract :) The first letters of each answer make up a code. Assemble the code and send your answers to gervixen@gmail.com
 * The first letter of each answer make up a code ;) send the code to gervixen@gmail.com
 */









































/**
 * Riddles?
 * What is the end of everything?
 * What kind of room has no doors or windows?
 * Which word in the dictionary is always spelled incorrectly?
 *
 * There are 4 riddles in this contract :) The first letters of each answer make up a code. Assemble the code and send your answers to gervixen@gmail.com
 * The first letter of each answer make up a code ;) send the code to gervixen@gmail.com
 */
