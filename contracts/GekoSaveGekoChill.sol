// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CustomString.sol";

contract GekoSaveGekoChill is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public currentSupply = 0;
    uint256 public totalSupply = 10000;
    uint256 public mintPrice = 0.12 ether;  // BNB
    uint256 public rewardFee = 80;  // 8% with 1000 uint for rewards to 100 top holders
    uint256 public devFee = 30;  // 3% with 1000 unit
    uint256 public rewardBalance = 0;
    uint256 public devBalance = 0;
    address public devWallet = 0x5eacBb8267458B6bAC84D4019Bb64CC1a35b248E;
    uint256 public maxMintNumber = 10;

    string public baseTokenURI = "https://ipfs.gekosave.io/metadata/";
    bool public paused = false;
    mapping (address=>uint256) private _tokenBalance;
    
    address[] public holders;
    struct Holder {
        uint256 index;
        bool exist;
    }
    mapping(address=>Holder) public checkHolders;
    mapping(address=>bool) public claimedAccount;
    
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
    event UpdateHolders(address[] _holders);
    event ChangePaused(bool _value);
    
    constructor() ERC721("GekoSave GekoChill", "GG") {}

    function changePaused() public onlyOwner {
        paused = !paused;
        emit ChangePaused(paused);
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

    function mintPunk(uint256 _numberOfTokens) public payable {
        require(!paused, "Minting is paused");
        require(_numberOfTokens <= maxMintNumber, "Too many tokens to mint at once.");
        require(currentSupply.add(_numberOfTokens) <= totalSupply, "No punks available for minting!");
        require(msg.value >= mintPrice.mul(_numberOfTokens), "Amount is not enough!");
        rewardBalance += msg.value.mul(rewardFee).div(1000);
        devBalance += msg.value.mul(devFee).div(1000);
        uint256 _punkIndex = currentSupply;
        currentSupply += _numberOfTokens;
        _tokenBalance[_msgSender()] += _numberOfTokens;
        for (uint256 i = 1; i <= _numberOfTokens; i++) {
            Punk storage newPunk = punks[_punkIndex.add(i)];
            newPunk.tokenId = _punkIndex.add(i);
            newPunk.creator = _msgSender();
            newPunk.owner = _msgSender();
            newPunk.uri = createTokenURI(_punkIndex.add(i));
            newPunk.ownershipRecords.push(_msgSender());
            _safeMint(_msgSender(), _punkIndex.add(i));
            emit PunkMint(_msgSender(), newPunk);
        }
        updateHolders(_msgSender());
    }

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return punks[_tokenId].creator;
    }

    function updateHolders(address _account) private {
        if (!checkHolders[_account].exist) {
            checkHolders[_account].index = holders.length;
            checkHolders[_account].exist = true;
            holders.push(_account);
        } else if (checkHolders[_account].exist && _tokenBalance[_account] == 0) {
            uint256 index = checkHolders[_account].index;
            holders[index] = holders[holders.length - 1];
            holders.pop();
            checkHolders[_account].exist = false;
        }
        emit UpdateHolders(holders);
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
        payable(_msgSender()).transfer(address(this).balance.sub(rewardBalance).sub(devBalance));
    }

    function withdrawByDev() public {
        require(_msgSender() == devWallet, "You are not a DEV!");
        payable(_msgSender()).transfer(devBalance);
        devBalance = 0;
    }

    function claimReward() public {
        require(paused, "You are unable to claim until mint has done.");
        require(!claimedAccount[_msgSender()], "You already claimed.");
        quickSort(holders, 0, uint256(holders.length - 1));
        bool isClaim = false;
        if (holders.length > 100) {
            for (uint256 i = holders.length - 1; i >= holders.length - 100; i--) {
                if (holders[i] == _msgSender()) {
                    isClaim = true;
                    break;
                }
            }
        } else {
            isClaim = true;
        }
        if (isClaim) {
            claimedAccount[_msgSender()] = true;
            uint256 claimAmount = rewardBalance.div(100);
            rewardBalance = rewardBalance.sub(claimAmount);
            payable(_msgSender()).transfer(claimAmount);
        }
    }

    function quickSort(address[] memory arr, uint256 left, uint256 right) private view {
        uint256 i = left;
        uint256 j = right;
        if (i == j) return;
        address pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (_tokenBalance[arr[uint256(i)]] < _tokenBalance[pivot]) i++;
            while (_tokenBalance[pivot] < _tokenBalance[arr[uint(j)]]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = punks[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // check punk index is available
        require(tokenId <= currentSupply, "Undefined tokenID!");
        // check owner of punk
        require(ownerOf(tokenId) == from, "Caller is not owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        punks[tokenId].owner = to;
        _tokenBalance[from]--;
        _tokenBalance[to]++;
        punks[tokenId].ownershipRecords.push(to);
        updateHolders(from);
        updateHolders(to);
        emit Transfer(from, to, tokenId);
    }
}
