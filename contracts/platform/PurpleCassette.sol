// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./LoyaltyBadge.sol";

contract PurpleCassette is
    ERC20,
    ERC20Snapshot,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl
{
    address public loyaltyBadgeAddress;

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // events for mint function
    event Mint(address indexed to, uint256 amount, string reason);

    constructor() ERC20("Purple Cassette", "PC") {
        // Grant the minter role to a specified account
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address _to,
        uint256 _amount,
        string memory _reason
    ) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
        emit Mint(_to, _amount, _reason);
    }

    function grantMinterRole(
        address _minter
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _minter);
    }

    function revokeMinterRole(
        address _minter
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, _minter);
    }

    function setLoyaltyBadgeAddress(
        address _loyaltyBadgeAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        loyaltyBadgeAddress = _loyaltyBadgeAddress;
    }

    function snapshot() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._afterTokenTransfer(from, to, amount);

        if (to != address(0)) {
            // check if the user has reached a new level
            bool levelUp = LoyaltyBadge(loyaltyBadgeAddress).checkLevelUp(
                to
            );
            // if the user has reached a new level, level up the user
            if (levelUp) {
                LoyaltyBadge(loyaltyBadgeAddress).levelUp(to);
            }
        }
    }
}
