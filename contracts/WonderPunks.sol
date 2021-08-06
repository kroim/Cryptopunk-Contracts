// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract WonderPunks is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 private _punkIndex = 0;
    uint256 public totalSupply = 11000;
    uint256 public currentSupply = 0;
    uint256 public maxPunksPurchase = 20;
    uint256 public mintPrice = 100000000 * 10 ** 9;  // 0.1ETH

    bool paused = true;

    struct Punk {
        address _pCreator;
        address _pOwner;
        string _pUri;
        address[] _pOwnershipRecords;
    }

    mapping(uint256=>Punk) public punks;
    mapping(address=>bool) public isMinter;

    constructor() ERC721("WonderPunks", "WDP") {
        
    }

    modifier onlyMinter() {
        require(isMinter[_msgSender()] || owner() == _msgSender(), "Caller is not minter!");
        _;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMaxPunksPurchase(uint256 _maxPunksPurchase) public onlyOwner {
        maxPunksPurchase = _maxPunksPurchase;
    }

    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return punks[_tokenId]._pUri;
    }

    function addMinter(address _minterAddress) public onlyOwner {
        require(_minterAddress != address(0), "Minter Address is the zero address");
        require(!isMinter[_minterAddress], "Already a minter");
        isMinter[_minterAddress] = true;
    }

    function removeMinter(address _minterAddress) public onlyOwner {
        require(_minterAddress != address(0), "Minter Address is the zero address");
        require(!isMinter[_minterAddress], "Not a minter");
        isMinter[_minterAddress] = false;
    }

    function mintPunk(uint256 _numberOf, string[] memory _uris) public payable onlyMinter {
        require(_numberOf > 0, "Empty data");
        require(_uris.length == _numberOf, "Invalid data");
        require(currentSupply + _numberOf <= totalSupply, "No punks available for minting!");
        if (_msgSender() != owner()) {
            require(msg.value >= mintPrice * _numberOf, "insufficient balance");
        }
        for (uint256 i = 0; i < _numberOf; i++) {
            uint256 _prevPunkIndex = _punkIndex;
            _punkIndex = _punkIndex.add(1);
            Punk storage newPunk = punks[_prevPunkIndex];
            newPunk._pCreator = msg.sender;
            newPunk._pOwner = msg.sender;
            newPunk._pUri = _uris[i];
            newPunk._pOwnershipRecords.push(address(0));
            _safeMint(msg.sender, _prevPunkIndex);
        }
    }

    function splitBalance(uint256 amount) private {
        
    }
}