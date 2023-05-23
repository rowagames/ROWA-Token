// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ROWAJournal is
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    AccessControl
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _partCounter;

    /**
     * @dev The maximum number of supply of each part.
     */
    mapping(uint256 => uint256) public maxPartSupply;

    /**
     * @dev The total supply of each part.
     */
    mapping(uint256 => uint256) public partToTotalSupply;

    /**
     * @dev The balances of each part for each address.
     */
    mapping(uint256 => mapping(uint256 => address)) public partToTokenToOwner;

    /**
     * @dev Mapping for parts to token IDs.
     */
    mapping(uint256 => uint256[]) public partToTokenIds;

    /**
     * @dev Mapping for token IDs to parts.
     */
    mapping(uint256 => uint256) public tokenIdToPart;

    /**
     * @dev Modifier for checking if the caller is authorized.
     */
    modifier onlyAuthorized() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(MINTER_ROLE, msg.sender),
            "Not authorized"
        );
        _;
    }

    /**
     * @dev Modifier for checking if the given part has a maximum supply.
     * @param part The part to check.
     */
    modifier hasMaxSupply(uint256 part) {
        require(maxPartSupply[part] > 0, "Maximum supply not set");
        _;
    }

    /**
     * @dev Modifier for checking if any token minted after the maximum supply is set.
     * @param part The part to check.
     */
    modifier hasNotExceededMaxSupply(uint256 part) {
        require(
            partToTokenIds[part].length <= 0,
            "Maximum supply can not be changed after minting"
        );
        _;
    }

    /**
     * @dev Constructor for the ROWAJournal contract.
     */
    constructor() ERC721("ROWAJournal", "RJ") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Mints a new token.
     * @param newPart Whether to create a new part.
     * @param part The part of the token.
     * @param to The address to mint the token to.
     * @param uri The URI of the token.
     */
    function mint(
        bool newPart,
        uint256 part,
        address to,
        string memory uri
    ) public onlyAuthorized hasMaxSupply(part) {
        require(
            partToTotalSupply[part] < maxPartSupply[part],
            "Maximum supply reached"
        );

        if (newPart) {
            part = _partCounter.current();
            _partCounter.increment();
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        partToTotalSupply[part].add(1);
        partToTokenIds[part].push(newTokenId);
        partToTokenToOwner[part][newTokenId] = to;
        tokenIdToPart[newTokenId] = part;
        _setTokenURI(newTokenId, uri);
        _tokenIdCounter.increment();
    }

    /**
     * @dev Sets the maximum supply of each part.
     * @param part The part to set the maximum supply for.
     * @param maxSupply The maximum supply of the part.
     */
    function setMaxPartSupply(
        uint256 part,
        uint256 maxSupply
    ) public onlyAuthorized hasNotExceededMaxSupply(part) {
        maxPartSupply[part] = maxSupply;
    }

    /**
     * @dev Returns the balance of a given part.
     * @param part The part to get the balance of.
     */
    function totalSupply(uint256 part) public view returns (uint256) {
        return partToTotalSupply[part];
    }

    /**
     * @dev Returns the active part count.
     */
    function partCount() public view returns (uint256) {
        return _partCounter.current();
    }

    /**
     * @dev Returns the active token count.
     */
    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (to == address(0)) {
            // Remove the token from the owner's balance.
            partToTokenToOwner[tokenIdToPart[tokenId]][tokenId] = address(0);
        } else {
            // Add the token to the new owner's balance.
            partToTokenToOwner[tokenIdToPart[tokenId]][tokenId] = to;
        }
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
