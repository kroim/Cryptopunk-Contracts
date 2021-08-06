/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract FunkiFoxes is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _fufoIDs;
    uint256 public totalSupply = 11000;

    uint256 totalAddedFromAttribute;
    struct attributeData {
        string name;
        uint256 totalCount;
        uint256 usedCount;
    }
    uint256 attributeCount = 92;
    uint256 totalAttributeCombination = 37537;
    uint256 attributeCounter;
    mapping(uint256 => attributeData) public attributes;
    mapping(uint256 => bool) isSetAttribute;
    struct previousOwner {
        address userAddress;
        uint256 startTime;
        uint256 endTime;
        bool isSet;
    }

    struct fufo {
        uint256 id;
        address creator;
        string uri;
        uint256[] attributes;
        uint256 CurrentOwnerstartTime;
        address[] ownershipRecords;
        mapping(uint256 => previousOwner) ownershipRecordData;
        bool isMinted;
    }
    uint256[] addedFufosID;
    uint256 mintIndex;
    mapping(uint256 => fufo) public shitFufos;
    mapping(address => bool) public isMinter;
    uint256 punkMintPrice = 10 ** 17;

    uint256 public minterBalance;
    uint256 public reflectionBalance;
    uint256 public totalDevident;
    mapping(uint256 => uint256) lastDevidentAt;

    constructor() ERC721("FunkiFoxes", "FUFO") {}

    modifier onlyMinter() {
        require(
            isMinter[_msgSender()] || owner() == _msgSender(),
            " caller has no minting right!!!"
        );
        _;
    }

    function addAttribute(uint256[] memory TotalCounts, string[] memory names) public onlyMinter{
        require(TotalCounts.length == names.length, "data mismatch");
        for (uint256 i = 0; i < names.length; i++) {
            attributeCounter++;
            uint256 TotalCount = TotalCounts[i];
            string memory name = names[i];
            require(
                attributeCounter <= attributeCount,
                "Attribute Count Exceeded"
            );
            require(
                (totalAddedFromAttribute + TotalCount) <=
                    totalAttributeCombination,
                "Count would Exceed supply"
            );
            require(
                !isSetAttribute[attributeCounter],
                "attribute ID already Added"
            );
            totalAddedFromAttribute += TotalCount;
            attributes[attributeCounter] = attributeData(name, TotalCount, 0);
            isSetAttribute[attributeCounter] = true;
        }
    }

    function getattributeName(uint256 id) public view returns (string memory) {
        require(id <= attributeCount, "invalid ID");
        require(isSetAttribute[id], "attribute not yet set");
        return attributes[id].name;
    }

    function addPunk(string memory uri, uint256[] memory _attributes) public onlyMinter returns (uint256){
        require(
            attributesAvailable(_attributes),
            "Please ensure to provide valid attributes"
        );
        _fufoIDs.increment();
        require(_fufoIDs.current() <= totalSupply, "Max Supply Reached");
        uint256 fufoID = _fufoIDs.current();

        fufo storage newshitfufo = shitFufos[fufoID];
        newshitfufo.id = fufoID;

        newshitfufo.uri = uri;
        newshitfufo.attributes = _attributes;
        newshitfufo.CurrentOwnerstartTime = block.timestamp;
        return fufoID;
    }

    function currentRate() public view returns (uint256) {
        if (currentSupply() == 0) return 0;
        return reflectionBalance / currentSupply();
    }

    function mintPunk(uint256 amount) public payable returns (uint256) {
        if (_msgSender() != owner()) {
            require(amount >= punkMintPrice, "amount below minting Price");
            require(msg.value >= punkMintPrice, "insufficient balance");
        }

        require(
            currentAddedFufos() > 0 && mintIndex < currentAddedFufos(),
            "no punks available for minting"
        );
        require(!shitFufos[mintIndex + 1].isMinted, "next ponk minted");

        mintIndex = mintIndex.add(1);
        _safeMint(msg.sender, mintIndex);
        lastDevidentAt[mintIndex] = totalDevident;
        if (_msgSender() != owner()) {
            splitBalance(msg.value);
        }

        fufo storage currentshitfufo = shitFufos[mintIndex];
        currentshitfufo.creator = _msgSender();
        currentshitfufo.CurrentOwnerstartTime = block.timestamp;
        currentshitfufo.isMinted = true;

        return currentshitfufo.id;
    }

    function splitBalance(uint256 amount) private {
        uint256 reflectionShare = amount.mul(5).div(100);
        uint256 mintingShare = amount.sub(reflectionShare);
        reflectDevident(reflectionShare);
        minterBalance = minterBalance.add(mintingShare);
    }

    function reflectToHolders(uint256 amount) public payable {
        require(msg.value >= amount, "insufficient balance");
        reflectDevident(amount);
    }

    function reflectDevident(uint256 amount) private {
        reflectionBalance = reflectionBalance.add(amount);
        totalDevident = totalDevident.add(amount.div(currentSupply()));
    }

    function attributesAvailable(uint256[] memory _attributes) private returns (bool){
        for (uint256 i; i < _attributes.length; i++) {
            uint256 attributeID = _attributes[i];
            if (!isSetAttribute[attributeID]) return false;
            if (
                attributes[attributeID].usedCount >=
                attributes[attributeID].totalCount
            ) return false;
            attributes[attributeID].usedCount++;
        }
        return true;
    }

    function currentAddedFufos() public view returns (uint256) {
        return _fufoIDs.current();
    }

    function previousFufoOwners(uint256 fufoID) public view returns (address[] memory){
        require(
            _exists(fufoID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return shitFufos[fufoID].ownershipRecords;
    }

    function previousFufoOwnerRecord(uint256 fufoID, uint256 previousOwnerIndex) public view returns (previousOwner memory){
        require(
            _exists(fufoID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(
            previousOwnerIndex < shitFufos[fufoID].ownershipRecords.length,
            "invalid previousOwnerIndex"
        );
        return shitFufos[fufoID].ownershipRecordData[previousOwnerIndex];
    }

    function punkAttributes(uint256 fufoID) public view returns (uint256[] memory){
        require(
            _exists(fufoID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return shitFufos[fufoID].attributes;
    }

    function _transfer(address from,address to,uint256 fufoID) internal virtual override {
        require(
            ERC721.ownerOf(fufoID) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        claimReward(fufoID);
        _beforeTokenTransfer(from, to, fufoID);

        // Clear approvals from the previous owner
        _approve(address(0), fufoID);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[fufoID] = to;

        fufo storage currentFufo = shitFufos[fufoID];

        uint256 ownershipIndex = currentFufo.ownershipRecords.length;
        previousOwner storage newPreviousOwner = currentFufo.ownershipRecordData[ownershipIndex];
        newPreviousOwner.userAddress = from;
        newPreviousOwner.startTime = currentFufo.CurrentOwnerstartTime;
        newPreviousOwner.endTime = block.timestamp;
        newPreviousOwner.isSet = true;

        currentFufo.ownershipRecords.push(from);
        currentFufo.CurrentOwnerstartTime = block.timestamp;

        emit Transfer(from, to, fufoID);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 fufoID) public view virtual override returns (string memory){
        require(
            _exists(fufoID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return shitFufos[fufoID].uri;
    }

    function tokenCreator(uint256 fufoID) public view virtual returns (address){
        require(
            _exists(fufoID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return shitFufos[fufoID].creator;
    }

    function addMinter(address MinterAddress) public onlyOwner {
        require(
            MinterAddress != address(0),
            " Minter Address is the zero address"
        );
        require(!isMinter[MinterAddress], " Already a minter");
        isMinter[MinterAddress] = true;
    }

    function removeMinter(address MinterAddress) public onlyOwner {
        require(
            MinterAddress != address(0),
            " Minter Address is the zero address"
        );
        require(!isMinter[MinterAddress], " not a minter");
        isMinter[MinterAddress] = false;
    }

    function claimReward(uint256 fufoID) public {
        uint256 balance = getReflectionBalance(fufoID);
        require(balance > 0, "nothing to claim");
        address payable receiver = payable(ownerOf(fufoID));
        receiver.transfer(balance);
        lastDevidentAt[fufoID] = totalDevident;
    }

    function withDrawMintersFee(address payable recipient, uint256 amount) public onlyOwner {
        require(amount <= minterBalance, "insufficient funds");
        recipient.transfer(amount);
        minterBalance.sub(amount);
    }

    function getReflectionBalance(uint256 fufoID) public view returns (uint256) {
        return totalDevident - lastDevidentAt[fufoID];
    }

    function currentSupply() public view returns (uint256) {
        return mintIndex;
    }

    function updateMintingPrice(uint256 amount) public onlyOwner {
        punkMintPrice = amount;
    }
}
