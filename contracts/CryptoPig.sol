// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CryptoPig is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 private _punkIndex = 0;
    uint256 public totalSupply = 5000;
    uint256 public currentSupply = 0;
    uint256 public maxPunksPurchase = 10;
    uint256 public mintPrice = 500 ether;  // 500 ONE
    uint256 private _devXFee = 20;  // 20%
    uint256 private _devYFee = 75;  // 75%
    address private _devWalletX;
    address private _devWalletY;
    uint256 private _devXBalance = 0;
    uint256 private _devYBalance = 0;
    uint256 public reflectionFee = 5;  // 5%
    uint256 public totalReflectionBalance = 0;

    bool paused = true;

    struct Punk {
        address _pCreator;
        address _pOwner;
        string _pUri;
        address[] _pOwnershipRecords;
    }

    mapping(uint256=>Punk) public punks;
    mapping(address=>bool) public isMinter;
    mapping(address=>uint256) private _pBalanceOf;
    mapping(address=>uint256) private _pWidthraws;

    constructor() ERC721("CryptoPig", "PIGGO") {
        _devWalletX = 0xBDA2e26669eb6dB2A460A9018b16495bcccF6f0a;
        _devWalletY = 0xBDA2e26669eb6dB2A460A9018b16495bcccF6f0a;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _pBalanceOf[account];
    }

    modifier onlyMinter() {
        require(isMinter[_msgSender()] || owner() == _msgSender(), "Caller is not minter!");
        _;
    }
    
    function withdrawDevX() public payable {
        require(msg.sender == _devWalletX, "You are not DevX!");
        uint256 balanceX = _devXBalance;
        _devXBalance = 0;
        payable(msg.sender).transfer(balanceX);
    }

    function withdrawDevY() public payable {
        require(msg.sender == _devWalletY, "You are not DevY!");
        uint256 balanceY = _devYBalance;
        _devYBalance = 0;
        payable(msg.sender).transfer(balanceY);
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
        currentSupply += _numberOf;
        _pBalanceOf[msg.sender] = _numberOf;
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

    function splitBalance(uint256 _amount) private {
        uint256 _devXAmount = _amount.mul(_devXFee).div(100);
        uint256 _reflectionAmount = _amount.mul(reflectionFee).div(100);
        uint256 _devYAmount = _amount.sub(_devXAmount).sub(_reflectionAmount);
        _devXBalance += _devXAmount;
        _devYBalance += _devYAmount;
        totalReflectionBalance += _reflectionAmount;
    }

    modifier onlyHolder() {
        require(_pBalanceOf[msg.sender] > 0, "This account is not holder!");
        _;
    }

    function claimReflection() public onlyHolder {
        uint256 withdrawedAmount = _pWidthraws[msg.sender];
        uint256 claimAmount = totalReflectionBalance.mul(_pBalanceOf[msg.sender]).div(currentSupply);
        require(withdrawedAmount < claimAmount, "You already claimed your reflection!");
        uint256 withdrawAmount = claimAmount.sub(withdrawedAmount);
        _pWidthraws[msg.sender] += withdrawAmount;
        payable(msg.sender).transfer(withdrawAmount);
    }
}