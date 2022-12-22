// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/URITemplate.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract nftFactory {
    string private constant _factoryTablePrefix = "bunana";
    ITablelandTables private _factoryTableland;
    uint256 public _factoryTableId;
    address private latestNFTContract;
    uint256 private indx = 0;

    constructor() {
        _factoryTableland = ITablelandTables(
            0xDA8EA22d092307874f30A1F277D1388dca0BA97a
        );
        _factoryTableId = _factoryTableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int, cid text, address text",
                _factoryTablePrefix
            )
        );
    }

    function insertToTable(
        string memory cid,
        uint256 index,
        address addr
    ) public {
        string memory values = string.concat(
            "'",
            Strings.toString(index),
            "','",
            cid,
            "','",
            string(abi.encodePacked(addr)),
            "'"
        );

        //// ADD NEW ROW OF DETAILS FOR EACH NFT MINTED
        _factoryTableland.runSQL(
            address(this),
            _factoryTableId,
            SQLHelpers.toInsert(
                _factoryTablePrefix, // prefix
                _factoryTableId, // table id
                "id,cid,address",
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
        indx++;
        // nftCollections.push(address(newcollection));
        insertToTable(cid, indx, address(newcollection));
        latestNFTContract = address(newcollection);
    }

    // function getDeployedcollections() public view returns (address[] memory) {
    //     return nftCollections;
    // }

    // function getDeployedcids() public view returns (string[] memory) {
    //     return CID;
    // }
}

contract CryptoDevs is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseURIString =
        "https://testnet.tableland.network/query?unwrap=true&extract=true&s=";
    //string private _contractURIString = "https://testnet.tableland.network/query?unwrap=true&extract=true&s=";
    ITablelandTables private _tableland;
    string _metadataTable;
    uint256 public _metadataTableId;
    string private _tablePrefix = "ching";
    string private _imageURI;
    string private _nftName;
    string private _nftSymbol;
    string private _nftDescription;
    string private _result;
    uint256 private tableId;
    string private _cid;
    string public trial;
    string public trial2;

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
        _tableland = ITablelandTables(
            0xDA8EA22d092307874f30A1F277D1388dca0BA97a
        );

        //// CREATE NULL TABLE FOR THIS NFT COLLECTION
        _metadataTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int, stage text, name text, description text, image text, likes int, comments int, shares int, cid text",
                _tablePrefix
            )
        );
        string memory dat = Strings.toString(_metadataTableId);
        _metadataTable = string(abi.encodePacked(_tablePrefix, "_5_", dat));
        // _tablePrefix=string(abi.encodePacked(_nftName,"_",_nftSymbol));
    }

    function safeMint(address to) public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        string memory values = string.concat(
            Strings.toString(newItemId),
            ",'starting','",
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
        );

        //// ADD NEW ROW OF DETAILS FOR EACH NFT MINTED
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            SQLHelpers.toInsert(
                _tablePrefix, // prefix
                _metadataTableId, // table id
                "id,stage,name,description,image,likes,comments,shares,cid",
                values
            )
        );
        _safeMint(to, newItemId, ""); /// MINT ONE NFT
        _tokenIds.increment();
        return newItemId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
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

    function updateTable(
        string memory id,
        string memory likes,
        string memory shares
    ) public {
        /// UPDATE EXISTING ROW OF THE TABLE BY USING ID
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            SQLHelpers.toUpdate(
                _tablePrefix, //prefix
                _metadataTableId, //table id
                // setters
                string.concat("likes = ", likes, ", shares = ", shares),
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
