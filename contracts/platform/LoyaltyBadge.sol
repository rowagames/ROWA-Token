// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title LoyaltyBadge
 * @author guraygrkn@protonmail.com
 * @notice This contract is used to mint loyalty badges for Rowa users. Loyalty badges are ERC721 tokens.
 */
contract LoyaltyBadge is ERC721, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // Counter for token IDs.
    Counters.Counter private _tokenIdCounter;

    // Purple Cassette Contract Address
    IERC20 private immutable pcContractAddress;

    ERC20Burnable _pcContractAddressBurnable;

    // Collection NFT Contract Address
    IERC20 private immutable collectionNFTContractAddress;

    // Maps user addresses to their loyalty badge token ID.
    mapping(address => uint256) public userToBadgeId;

    // Supported Number of levels
    uint256 public constant LEVEL_COUNT = 10;

    // Level 1: Create an account (no badge)
    uint256 public constant LEVEL_1_MIN_PURPLE_CASSETTES = 0;
    // Level 2: Min 10 Purple Cassette
    uint256 public constant LEVEL_2_MIN_PURPLE_CASSETTES = 10;
    // Level 3: Min 25 Purple Cassettes
    uint256 public constant LEVEL_3_MIN_PURPLE_CASSETTES = 25;
    // Level 4: Min 50 Purple Cassettes
    uint256 public constant LEVEL_4_MIN_PURPLE_CASSETTES = 50;
    // Level 5: 100 Purple Cassettes and 2 Collection NFTs (special level - need to be owned at the time to gain benefits of this level)
    uint256 public constant LEVEL_5_MIN_PURPLE_CASSETTES = 100;
    uint256 public constant LEVEL_5_MIN_COLLECTION_NFTS = 2;
    mapping(address => bool) public level5SatisfiedAtLeastOnce;
    // Level 6: Min 50 Purple Cassettes
    uint256 public constant LEVEL_6_MIN_PURPLE_CASSETTES = 50;
    // Level 7: Min 50 Purple Cassettes
    uint256 public constant LEVEL_7_MIN_PURPLE_CASSETTES = 50;
    // Level 8: Min 50 Purple Cassettes
    uint256 public constant LEVEL_8_MIN_PURPLE_CASSETTES = 50;
    // Level 9: Min 50 Purple Cassettes
    uint256 public constant LEVEL_9_MIN_PURPLE_CASSETTES = 50;
    // Level 10: Min 200 Purple Cassettes and 4 Collection NFTs (special level - need to be owned at the time to gain benefits of this level)
    uint256 public constant LEVEL_10_MIN_PURPLE_CASSETTES = 200;
    uint256 public constant LEVEL_10_MIN_COLLECTION_NFTS = 4;
    mapping(address => bool) public level10SatisfiedAtLeastOnce;
    // Level 10+: Min 50 Purple Cassettes
    uint256 public constant LEVEL_10_PLUS_MIN_PURPLE_CASSETTES = 50;

    uint256[] totalPurpleCassetteRequiredForEachLevel;

    // Maps user addresses to their loyalty badge level.
    mapping(address => uint256) public userToLevel;

    // Events
    event LevelUp(address indexed user, uint256 indexed level);

    modifier newUser(address user) {
        require(userToBadgeId[user] == 0, "User have a loyalty badge.");
        _;
    }

    /**
     * @notice Constructor for LoyaltyBadge contract.
     * @param _pcContractAddress Purple Cassette contract address.
     * @param _collectionNFTContractAddress Collection NFT contract address.
     */
    constructor(
        address _pcContractAddress,
        address _collectionNFTContractAddress
    ) ERC721("Loyalty Badge", "LB") {
        pcContractAddress = IERC20(_pcContractAddress);
        _pcContractAddressBurnable = ERC20Burnable(_pcContractAddress);
        collectionNFTContractAddress = IERC20(_collectionNFTContractAddress);

        // Start the token ID counter from 1. 0 is reserved for the "no badge" state.
        _tokenIdCounter.increment();

        // Initialize the purple cassette requirements for each level.
        for (uint256 i = 0; i < LEVEL_COUNT + 1; i++) {
            uint256 level = i;
            uint256 minPurpleCassettesForLevel = _getMinPurpleCassettesForLevel(
                level
            );
            if (level == 0) {
                totalPurpleCassetteRequiredForEachLevel.push(0);
            } else {
                totalPurpleCassetteRequiredForEachLevel.push(
                    totalPurpleCassetteRequiredForEachLevel[level - 1] +
                        minPurpleCassettesForLevel
                );
            }
        }
    }

    /**
     * @notice safeMint a loyalty badge for the given user.
     */
    function mint() public newUser(msg.sender) {
        address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        userToBadgeId[to] = tokenId;
        _safeMint(to, tokenId);

        // Level up the user if they satisfy the requirements.
        levelUp(to);
    }

    /**
     * @notice Level up the user if they have enough Purple Cassettes and Collection NFTs in their wallet.
     * @param user User address.
     * @dev This function is called by the Purple Cassette contract when a user transfers Purple Cassettes to another user or mint/burns Purple Cassettes.
     * @dev This function is called by the Collection NFT contract when a user transfers Collection NFTs to another user or mint/burns Collection NFTs.
     * @dev This function can be called by anyone to level up the user manually if they satisfy the requirements.
     */
    function levelUp(address user) public nonReentrant {
        require(
            userToBadgeId[user] != 0,
            "User does not have a loyalty badge."
        );

        uint256 userPcBalance = pcContractAddress.balanceOf(user);
        uint256 userCollectionNFTBalance = collectionNFTContractAddress
            .balanceOf(user);
        uint256 userLevel = userToLevel[user];
        uint256 needToBurn = 0;
        uint256 newLevel = userLevel;
        if (userLevel >= 10) {
            uint256 numberOfLevelsCanLevelUp = userPcBalance /
                LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
            needToBurn =
                numberOfLevelsCanLevelUp *
                LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
            newLevel = userLevel + numberOfLevelsCanLevelUp;
        } else {
            uint256 alreadyBurned = totalPurpleCassetteRequiredForEachLevel[
                userLevel
            ];
            for (
                uint256 i = userLevel + 1;
                i < totalPurpleCassetteRequiredForEachLevel.length;
                i++
            ) {
                if (
                    userPcBalance >=
                    totalPurpleCassetteRequiredForEachLevel[i] - alreadyBurned
                ) {
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[i] -
                        alreadyBurned;
                    newLevel = i;
                } else {
                    break;
                }
            }

            if (userLevel < 5 && newLevel >= 5) {
                if (userCollectionNFTBalance < LEVEL_5_MIN_COLLECTION_NFTS) {
                    newLevel = 4;
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[4] -
                        alreadyBurned;
                } else {
                    level5SatisfiedAtLeastOnce[user] = true;
                }
            }
            if (userLevel < 10 && newLevel >= 10) {
                if (
                    userCollectionNFTBalance < LEVEL_10_MIN_COLLECTION_NFTS ||
                    !level5SatisfiedAtLeastOnce[user]
                ) {
                    newLevel = 9;
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[9] -
                        alreadyBurned;
                } else {
                    level10SatisfiedAtLeastOnce[user] = true;
                    uint256 numberOfLevelsCanLevelUp = userPcBalance /
                        LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[10] -
                        alreadyBurned +
                        numberOfLevelsCanLevelUp *
                        LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
                    newLevel = 10 + numberOfLevelsCanLevelUp;
                }
            }
        }

        if (needToBurn > 0) {
            _pcContractAddressBurnable.burnFrom(user, needToBurn);
            userToLevel[user] = newLevel;
            emit LevelUp(user, newLevel);
        }
    }

    /**
     * @notice Get the level of the user.
     * @param user User address.
     * @return User level.
     */
    function getLevel(address user) external view returns (uint256) {
        return userToLevel[user];
    }

    /**
     * @notice Get the badge ID of the user.
     * @param user User address.
     * @return User badge ID.
     */
    function getBadgeId(address user) external view returns (uint256) {
        return userToBadgeId[user];
    }

    /**
     * @notice check if the user level can be upgraded.
     * @param user User address.
     * @return true if the user level can be upgraded.
     */
    function checkLevelUp(address user) external view returns (bool) {
        require(
            userToBadgeId[user] != 0,
            "User does not have a loyalty badge."
        );

        uint256 userPcBalance = pcContractAddress.balanceOf(user);
        uint256 userCollectionNFTBalance = collectionNFTContractAddress
            .balanceOf(user);
        uint256 userLevel = userToLevel[user];
        uint256 needToBurn = 0;
        uint256 newLevel = userLevel;
        if (userLevel >= 10) {
            uint256 numberOfLevelsCanLevelUp = userPcBalance /
                LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
            needToBurn =
                numberOfLevelsCanLevelUp *
                LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
            newLevel = userLevel + numberOfLevelsCanLevelUp;
        } else {
            uint256 alreadyBurned = totalPurpleCassetteRequiredForEachLevel[
                userLevel
            ];
            for (
                uint256 i = userLevel + 1;
                i < totalPurpleCassetteRequiredForEachLevel.length;
                i++
            ) {
                if (
                    userPcBalance >=
                    totalPurpleCassetteRequiredForEachLevel[i] - alreadyBurned
                ) {
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[i] -
                        alreadyBurned;
                    newLevel = i;
                } else {
                    break;
                }
            }

            if (userLevel < 5 && newLevel >= 5) {
                if (userCollectionNFTBalance < LEVEL_5_MIN_COLLECTION_NFTS) {
                    newLevel = 4;
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[4] -
                        alreadyBurned;
                }
            }
            if (userLevel < 10 && newLevel >= 10) {
                if (
                    userCollectionNFTBalance < LEVEL_10_MIN_COLLECTION_NFTS ||
                    !level5SatisfiedAtLeastOnce[user]
                ) {
                    newLevel = 9;
                    needToBurn =
                        totalPurpleCassetteRequiredForEachLevel[9] -
                        alreadyBurned;
                }
            }
        }

        if (newLevel > userLevel) {
            return true;
        }

        return false;
    }

    /**
     * @notice Get the level 5 satisfying status of the user.
     * @param user User address.
     * @return true if the user has satisfied the level 5 requirements actively.
     */
    function getLevel5SatisfyingStatus(
        address user
    ) public view returns (bool) {
        uint256 userPcBalance = pcContractAddress.balanceOf(user);
        uint256 userCollectionNFTBalance = collectionNFTContractAddress
            .balanceOf(user);

        bool level5Satisfied = userPcBalance >= LEVEL_5_MIN_PURPLE_CASSETTES &&
            userCollectionNFTBalance >= LEVEL_5_MIN_COLLECTION_NFTS;

        if (level5Satisfied && userToLevel[user] >= 5) {
            return true;
        }

        return false;
    }

    /**
     * @notice Get the level 10 satisfying status of the user.
     * @param user User address.
     * @return true if the user has satisfied the level 10 requirements actively.
     */
    function getLevel10SatisfyingStatus(address user) public returns (bool) {
        uint256 userPcBalance = pcContractAddress.balanceOf(user);
        uint256 userCollectionNFTBalance = collectionNFTContractAddress
            .balanceOf(user);

        bool level10Satisfied = userPcBalance >=
            LEVEL_10_MIN_PURPLE_CASSETTES &&
            userCollectionNFTBalance >= LEVEL_10_MIN_COLLECTION_NFTS;

        if (level10Satisfied) {
            if (userToLevel[user] < 10) {
                // level 10 has been satisfied and the user is not level 10 yet.
                // this means that the user has satisfied the level 10 requirements actively but has not been levelled up yet.
                // level up the user.
                levelUp(user);
            }
            return true;
        } else {
            return false;
        }
    }

    function getTotalPurpleCassettesRequiredForEachLevel()
        external
        view
        returns (uint256[] memory)
    {
        return totalPurpleCassetteRequiredForEachLevel;
    }

    function _getMinPurpleCassettesForLevel(
        uint256 level
    ) internal pure returns (uint256) {
        if (level == 0) {
            return 0;
        } else if (level == 1) {
            return LEVEL_1_MIN_PURPLE_CASSETTES;
        } else if (level == 2) {
            return LEVEL_2_MIN_PURPLE_CASSETTES;
        } else if (level == 3) {
            return LEVEL_3_MIN_PURPLE_CASSETTES;
        } else if (level == 4) {
            return LEVEL_4_MIN_PURPLE_CASSETTES;
        } else if (level == 5) {
            return LEVEL_5_MIN_PURPLE_CASSETTES;
        } else if (level == 6) {
            return LEVEL_6_MIN_PURPLE_CASSETTES;
        } else if (level == 7) {
            return LEVEL_7_MIN_PURPLE_CASSETTES;
        } else if (level == 8) {
            return LEVEL_8_MIN_PURPLE_CASSETTES;
        } else if (level == 9) {
            return LEVEL_9_MIN_PURPLE_CASSETTES;
        } else if (level == 10) {
            return LEVEL_10_MIN_PURPLE_CASSETTES;
        } else {
            return LEVEL_10_PLUS_MIN_PURPLE_CASSETTES;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal pure override {
        require(
            from == address(0) || to != address(0),
            "Loyalty Badge tokens cannot be transferred and cannot be burned."
        );
    }

    function _burn(uint256) internal pure override {
        revert(
            "Loyalty Badge tokens cannot be transferred and cannot be burned."
        );
    }
}
