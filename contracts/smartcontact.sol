// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract nftFactory {
    address[] nftCollections;
    string[] CID;

    function createcollection(
        string memory baseuri,
        string memory nftname,
        string memory symbol,
        string memory cid
    ) public returns (address) {
        CryptoDevs newcollection = new CryptoDevs(
            baseuri,
            msg.sender,
            nftname,
            symbol
        );
        CID.push(cid);
        nftCollections.push(address(newcollection));
        return address(newcollection);
    }

    function getDeployedcollections() public view returns (address[] memory) {
        return nftCollections;
    }

    function getDeployedcids() public view returns (string[] memory) {
        return CID;
    }
}

contract CryptoDevs is ERC721Enumerable, Ownable {
    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string _baseTokenURI;
    using SafeMath for uint256;
    uint256 like;

    uint256 mintip = 0.000000001 ether;

    //  _price is the price of one Crypto Dev NFT
    uint256 public _price = 0.0001 ether;

    // _paused is used to pause the contract in case of an emergency
    bool public _paused;

    // max number of CryptoDevs
    uint256 public maxTokenIds = 20;

    // total number of tokenIds minted
    uint256 public tokenIds;

    address _realowner;

    modifier onlyrealOwner() {
        require(
            msg.sender == _realowner,
            "you are not the owner of this collection"
        );
        _;
    }

    /**
     * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
     * name in our case is `Crypto Devs` and symbol is `CD`.
     * Constructor for Crypto Devs takes in the baseURI to set _baseTokenURI for the collection.
     * It also initializes an instance of whitelist interface.
     */
    constructor(
        string memory baseURI,
        address realOwner,
        string memory nftname,
        string memory symbol
    ) ERC721(nftname, symbol) {
        _baseTokenURI = baseURI;
        _realowner = realOwner;
    }

    /**
     * @dev mint allows a user to mint 1 NFT per transaction after the presale has ended.
     */
    function mint() public payable onlyrealOwner {
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(_realowner, tokenIds); //send minted nft to owner
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tip(uint256 _tokenId) external payable {
        require(msg.value > mintip, "please send more");
    }

    function divideBytoken(uint256 num) public view returns (uint256) {
        return num.div(tokenIds);
    }

    /**
     * @dev withdraw sends all the ether in the contract
     * to the owner of the contract
     */
    function withdraw() public onlyrealOwner {
        address _owner = _realowner;
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function likeplus() public {
        like = like + 1;
    }

    function splitshare() public {
        uint256 netbalance = address(this).balance;
        uint256 splitamount = divideBytoken(netbalance);
        for (uint i = 0; i < tokenIds; i++) {
            (bool sent, ) = ownerOf(i).call{value: splitamount}("");
            require(sent, "Failed to send Ether");
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
