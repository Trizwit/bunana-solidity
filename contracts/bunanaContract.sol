// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
// import "@tableland/evm/contracts/utils/URITemplate.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract nftFactory {
    ITablelandTables private constant _factoryTableland =
        ITablelandTables(0xDA8EA22d092307874f30A1F277D1388dca0BA97a);
    uint256 public _factoryTableId;
    uint256 private indx = 0;

    constructor() {
        _factoryTableId = _factoryTableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int, cid text, address text, tableid text",
                "bunana"
            )
        );
    }

    function insertToTable(
        string memory cid,
        uint256 index,
        address addr,
        string memory tableid
    ) private {
        string memory values = string.concat(
            "'",
            Strings.toString(index),
            "','",
            cid,
            "','",
            Strings.toHexString(uint160(addr), 20),
            "','",
            tableid,
            "'"
        );

        //// ADD NEW ROW OF DETAILS FOR EACH NFT MINTED
        _factoryTableland.runSQL(
            address(this),
            _factoryTableId,
            SQLHelpers.toInsert(
                "bunana", // prefix
                _factoryTableId, // table id
                "id,cid,address,tableid",
                values
            )
        );
    }

    // /// comment this function to deploy
    function createcollection(
        string memory cid,
        string memory nftName,
        string memory nftSymbol,
        string memory nftDescription,
        string memory imageURL
    ) public {
        CryptoDevs newcollection = new CryptoDevs(
            nftName,
            nftSymbol,
            nftDescription,
            imageURL,
            cid
        );
        insertToTable(
            cid,
            indx,
            address(newcollection),
            newcollection._metadataTable()
        );
        indx = indx + 1;
    }
}

contract CryptoDevs is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private constant _baseURIString =
        "https://testnet.tableland.network/query?unwrap=true&extract=true&s=";
    //string private _contractURIString = "https://testnet.tableland.network/query?unwrap=true&extract=true&s=";
    ITablelandTables private constant _tableland =
        ITablelandTables(0xDA8EA22d092307874f30A1F277D1388dca0BA97a);
    string public _metadataTable;
    uint256 private _metadataTableId;
    //string private _tablePrefix="ching";
    string private _imageURI;
    string private _nftName;
    string private _nftSymbol;
    string private _nftDescription;
    uint256 private tableId;
    string private _cid;
    uint256 private totalLikes = 0;
    uint256 private totalShares = 0;
    uint256 private totalComments = 0;

    using SafeMath for uint256;
    //uint256 like;

    uint256 private constant mintip = 0.000000001 ether;

    //  _price is the price of one Crypto Dev NFT
    uint256 private constant _price = 0.0001 ether;

    // _paused is used to pause the contract in case of an emergency
    bool private _paused;

    // max number of CryptoDevs
    uint256 private constant maxTokenIds = 20;

    // total number of tokenIds minted
    uint256 private tokenIds;

    address _realowner;

    modifier onlyrealOwner() {
        require(
            msg.sender == _realowner,
            "you are not the owner of this collection"
        );
        _;
    }

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory nftDescription,
        string memory imageURL,
        string memory cid
    ) ERC721(nftName, nftSymbol) {
        // _baseTokenURI = baseURI;
        // _realowner=realOwner;
        _nftName = nftName;
        _nftSymbol = nftSymbol;
        _imageURI = imageURL;
        _nftDescription = nftDescription;
        _cid = cid;
        // _tableland = ITablelandTables(0xDA8EA22d092307874f30A1F277D1388dca0BA97a);

        //// CREATE NULL TABLE FOR THIS NFT COLLECTION
        _metadataTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int, symbol text, name text, description text, image text, likes int, comments int, shares int, cid text",
                "ching"
            )
        );
        _metadataTable = string(
            abi.encodePacked("ching", "_5_", Strings.toString(_metadataTableId))
        );
        // _tablePrefix=string(abi.encodePacked(_nftName,"_",_nftSymbol));
    }

    function safeMint() public payable returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        require(
            msg.value > _price && newItemId < maxTokenIds,
            "Insufficient funds"
        );

        //// ADD NEW ROW OF DETAILS FOR EACH NFT MINTED
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            SQLHelpers.toInsert(
                "ching", // prefix
                _metadataTableId, // table id
                "id,symbol,name,description,image,likes,comments,shares,cid",
                string.concat(
                    Strings.toString(newItemId),
                    ",'",
                    _nftSymbol,
                    "','",
                    _nftName,
                    " ",
                    Strings.toString(newItemId),
                    "','",
                    _nftDescription,
                    "','",
                    _imageURI,
                    "',0,0,0,'",
                    _cid,
                    "'"
                )
            )
        );
        _safeMint(msg.sender, newItemId, ""); /// MINT ONE NFT
        _tokenIds.increment();
        return newItemId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        /// RETURNS THE URL TO GET METADATA OF EACH NFT
        return
            string.concat(
                _baseURIString,
                "SELECT+json_object%28%27id%27%2C+id%2C+%27name%27%2C+name%2C+%27image%27%2C+image%2C+%27description%27%2C+description%29+FROM+",
                string(_metadataTable),
                "+WHERE+id%3D",
                Strings.toString(tokenId)
            );
    }

    function updateParam(string memory id, uint cmd) public {
        string memory values;
        if (cmd == 0) {
            totalShares = totalShares + 1;
            values = string.concat("shares = ", Strings.toString(totalShares));
        } else if (cmd == 1) {
            totalLikes = totalLikes + 1;
            values = string.concat("likes = ", Strings.toString(totalLikes));
        } else if (cmd == 2) {
            totalComments = totalComments + 1;
            values = string.concat(
                "comments = ",
                Strings.toString(totalComments)
            );
        }

        /// UPDATE EXISTING LIKES OF THE TABLE BY USING ID
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            SQLHelpers.toUpdate(
                "ching", //prefix
                _metadataTableId, //table id
                // setters
                values,
                // where conditions
                string.concat("id = ", id)
            )
        );
    }

    function tip() external payable {
        require(msg.value > mintip, "please send more");
    }

    function divideBytoken(uint256 num) public view returns (uint256) {
        return num.div(tokenIds);
    }

    function withdraw() public onlyrealOwner {
        address _owner = _realowner;
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
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
