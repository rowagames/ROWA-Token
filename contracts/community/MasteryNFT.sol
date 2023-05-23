// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../platform/PurpleCassette.sol";

/**
 * @title Mastery NFT
 * @author guraygrkn@protonmail.com
 * @notice This contract is used for minting Mastery NFTs.
 */
contract Mastery is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // PurpleCassette contract address
    PurpleCassette public purpleCassette;

    // Whitelisted addresses for minting
    mapping(address => bool) public whitelisted;
    // Addresses that earned purple cassette
    mapping(address => bool) public earnedPurpleCassette;

    // Pass types
    enum passType {
        NONE,
        DIAMOND,
        RUBY,
        JADEITE
    }

    // Rewards
    uint256 public diamondReward = 45;
    uint256 public rubyReward = 85;
    uint256 public jadeiteReward = 185;

    // address mapping to allowed pass type.
    mapping(address => passType) public allowedPass;
    // tokenId mapping to pass type.
    mapping(uint256 => passType) public tokenPass;

    // Events
    event EarnedPurpleCassette(address indexed _address);

    // modifiers
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    modifier onlyAllowedPass() {
        require(
            allowedPass[msg.sender] != passType.NONE,
            "Not allowed to mint"
        );
        _;
    }

    modifier onlyNotEarnedPurpleCassette() {
        require(
            !earnedPurpleCassette[msg.sender],
            "Already earned purple cassette"
        );
        _;
    }

    modifier purpleCassetteSet() {
        require(
            address(purpleCassette) != address(0),
            "Purple cassette not set"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /**
     *
     * @param to address to mint to
     * @param uri token uri
     */
    function safeMint(
        address to,
        string memory uri
    ) public onlyWhitelisted nonReentrant {
        // check if the balance is 0. If it is not error out
        require(balanceOf(to) == 0, "Already minted");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        tokenPass[tokenId] = allowedPass[msg.sender];
    }

    /**
     * @notice get the pass type of the token id
     * @param tokenId token id to get the pass type of
     */
    function getPassType(uint256 tokenId) public view returns (passType) {
        return tokenPass[tokenId];
    }

    /**
     * @notice get the pass type of the token id as string
     * @param tokenId token id to get the pass type of
     */
    function getPassTypeString(
        uint256 tokenId
    ) public view returns (string memory) {
        if (tokenPass[tokenId] == passType.DIAMOND) {
            return "DIAMOND";
        } else if (tokenPass[tokenId] == passType.RUBY) {
            return "RUBY";
        } else if (tokenPass[tokenId] == passType.JADEITE) {
            return "JADEITE";
        } else {
            return "UNKNOWN";
        }
    }

    /**
     * @notice set the whitelisted status of an address
     * @param _address address to set whitelisted
     * @param _whitelisted  whitelisted status
     */
    function setWhitelisted(
        address _address,
        bool _whitelisted
    ) public onlyOwner onlyNotEarnedPurpleCassette {
        whitelisted[_address] = _whitelisted;
    }

    /**
     * @notice set the allowed pass type of an address
     * @param _address address to set allowed pass
     * @param _passType  pass type to set
     */
    function setAllowedPass(
        address _address,
        passType _passType
    ) public onlyOwner onlyNotEarnedPurpleCassette {
        allowedPass[_address] = _passType;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address];
    }

    /**
     * @notice check if an address can upgrade pass or not
     * @param _address address to check if it can upgrade pass
     * @return true if it can upgrade pass, false otherwise
     * @dev if the address has no token, it can upgrade pass.
     */
    function canUpragePass(address _address) public view returns (bool) {
        if (allowedPass[_address] == passType.NONE) {
            return false;
        }
        if (balanceOf(_address) == 0) {
            return true;
        }

        // get the token id of the address
        uint256 tokenId = tokenOfOwnerByIndex(_address, 0);
        if (tokenPass[tokenId] != allowedPass[_address]) {
            return true;
        }

        return false;
    }

    /**
     *
     * @param _address set the purple casette contract address
     */
    function setPurpleCasette(address _address) public onlyOwner {
        purpleCassette = PurpleCassette(_address);
    }

    /**
     * @notice earn purple casette if the address has a token. It mints the purple casette to the address according to the token type.
     * @dev It can only be called once per address.
     */
    function earnPurpleCasette()
        public
        purpleCassetteSet
        onlyWhitelisted
        onlyNotEarnedPurpleCassette
    {
        require(balanceOf(msg.sender) > 0, "No token minted");

        string memory passTypeString = getPassTypeString(
            tokenOfOwnerByIndex(msg.sender, 0)
        );

        // get the token id of the address
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        // check if the token is a diamond
        if (tokenPass[tokenId] == passType.DIAMOND) {
            // mint a purple casette
            purpleCassette.mint(msg.sender, diamondReward, passTypeString);
        } else if (tokenPass[tokenId] == passType.RUBY) {
            // mint a purple casette
            purpleCassette.mint(msg.sender, rubyReward, passTypeString);
        } else if (tokenPass[tokenId] == passType.JADEITE) {
            // mint a purple casette
            purpleCassette.mint(msg.sender, jadeiteReward, passTypeString);
        }

        // burn the token
        _burn(tokenId);

        delete tokenPass[tokenId];
        delete allowedPass[msg.sender];
        delete whitelisted[msg.sender];

        // set the earned purple casette to true
        earnedPurpleCassette[msg.sender] = true;

        // emit the event
        emit EarnedPurpleCassette(msg.sender);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // if the token is being transferred to a new owner, check if the new owner has a token already
        // if they do, revert the transaction
        if (from != address(0) && to != address(0)) {
            require(balanceOf(to) == 0, "Already minted");
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
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
