// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CryptoPig is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private _punkIndex = 0;
    uint256 public totalSupply = 5000;
    uint256 public currentSupply = 0;
    uint256 public maxPunksPurchase = 10;
    uint256 public mintPrice = 500 ether;  // 500 ONE
    uint256 public _devXFee = 20;  // 20%
    uint256 public _devYFee = 75;  // 75%
    address public _devWalletX;
    address public _devWalletY;
    uint256 public _devXBalance = 0;
    uint256 public _devYBalance = 0;
    uint256 public reflectionFee = 5;  // 5%
    uint256 public totalReflectionBalance = 0;

    uint256 public mintablePaused = 0;

    struct Punk {
        address _pCreator;
        address _pOwner;
        string _pUri;
        uint256 _tokenId;
        address[] _pOwnershipRecords;
    }

    mapping(uint256=>Punk) public punks;
    mapping(address=>bool) public isMinter;
    mapping(address=>uint256) private _pBalanceOf;  // balance of nfts
    mapping(address=>uint256) private _pWidthraws;  // amount of claims

    event PunkMint(address indexed to, Punk _punk);
    event ClaimReflection(address indexed account, uint256 amount);

    constructor() ERC721("CryptoPig", "PIGGO") {
        _devWalletX = 0xdc57e257b65c8496EBA5780DAD44B86Fe78eCDbF;
        _devWalletY = 0xEB8BC8F7801c46DA134f0B828Fa1Cc557019220b;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _pBalanceOf[account];
    }

    function setDevX(address _devX) public onlyOwner {
        _devWalletX = _devX;
    }
    
    function setDevY(address _devY) public onlyOwner {
        _devWalletY = _devY;
    }

    function withdrawDevX() public nonReentrant {
        require(msg.sender == _devWalletX, "You are not DevX!");
        payable(msg.sender).transfer(_devXBalance);
        _devXBalance = 0;
    }

    function withdrawDevY() public nonReentrant {
        require(msg.sender == _devWalletY, "You are not DevY!");
        payable(msg.sender).transfer(_devYBalance);
        _devYBalance = 0;
    }

    function setMaxPunksPurchase(uint256 _maxPunksPurchase) public onlyOwner {
        maxPunksPurchase = _maxPunksPurchase;
    }

    function setPaused(uint256 _mintablePaused) public onlyOwner {
        mintablePaused = _mintablePaused;
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

    function mintPunk(string memory _uri) public payable {
        require(mintablePaused == 1, "Minting is paused");
        uint256 _numberOf = 1;
        require(currentSupply + _numberOf <= totalSupply, "No punks available for minting!");
        if (_msgSender() != owner()) {
            require(msg.value >= mintPrice.mul(_numberOf), "insufficient balance");
        }
        currentSupply += _numberOf;
        _pBalanceOf[msg.sender] = _numberOf;
        splitBalance(msg.value);
        for (uint256 i = 0; i < _numberOf; i++) {
            uint256 _prevPunkIndex = _punkIndex;
            _punkIndex = _punkIndex.add(1);
            Punk storage newPunk = punks[_prevPunkIndex];
            newPunk._pCreator = msg.sender;
            newPunk._pOwner = msg.sender;
            newPunk._pUri = _uri;
            newPunk._tokenId = _prevPunkIndex;
            newPunk._pOwnershipRecords.push(msg.sender);
            _safeMint(msg.sender, _prevPunkIndex);
            emit PunkMint(msg.sender, newPunk);
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

    /**
        claim reflection
        the claim amount is saved, and it current reflection is bigger than claimed amount,
        the user can claim the rest amount continue. If less, the user can't claim
     */
    function claimReflection() public onlyHolder {
        require(mintablePaused != 1, "You can claim your reward after Minting has done!");
        uint256 withdrawedAmount = _pWidthraws[msg.sender];
        uint256 claimAmount = totalReflectionBalance.mul(_pBalanceOf[msg.sender]).div(currentSupply);
        require(withdrawedAmount < claimAmount, "You already claimed your reflection!");
        uint256 withdrawAmount = claimAmount.sub(withdrawedAmount);
        _pWidthraws[msg.sender] += withdrawAmount;
        payable(msg.sender).transfer(withdrawAmount);
        emit ClaimReflection(msg.sender, withdrawAmount);
    }

    // override token transfer function
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId <= currentSupply, "Undefined punk index!");
        // check owner of punk
        require(punks[tokenId]._pOwner == from, "Caller is not owner");
        punks[tokenId]._pOwner = to;
        _pBalanceOf[from]--;
        _pBalanceOf[to]++;
        punks[tokenId]._pOwnershipRecords.push(to);
        emit Transfer(from, to, tokenId);
    }

    modifier onlyMinter() {
        require(isMinter[_msgSender()] || owner() == _msgSender(), "Caller is not minter!");
        _;
    }
}