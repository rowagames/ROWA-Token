// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RowaToken
 * @author guraygrkn@gmail.com
 * @notice ERC20 token with snapshot and vesting support
 */
contract RowaToken is
    ERC20,
    ERC20Snapshot,
    ERC20Burnable,
    ERC20Pausable,
    Ownable
{
    address public vestingContract;

    // Token Information
    string public constant NAME = "ROWA Token";
    string public constant SYMBOL = "ROWA";
    uint8 public constant DECIMALS = 5;
    uint256 public constant INITIAL_SUPPLY =
        1_000_000_000 * 10 ** uint256(DECIMALS);

    // start time
    uint256 public startTime;

    event ContractPaused();
    event ContractUnpaused();
    event SnapshotCreated(uint256 id);
    event VestingStarted(address vestingContract);

    constructor() ERC20(NAME, SYMBOL) {}

    function snapshot() external onlyOwner {
        _snapshot();

        emit SnapshotCreated(_getCurrentSnapshotId());
    }

    function pause() external onlyOwner {
        _pause();

        emit ContractPaused();
    }

    function unpause() external onlyOwner {
        _unpause();

        emit ContractUnpaused();
    }

    function startVesting(address _vestingContract) external onlyOwner {
        require(
            _vestingContract != address(0),
            "ROWAToken: vesting contract is the zero address"
        );
        require(startTime == 0, "ROWAToken: vesting already started");
        vestingContract = _vestingContract;

        startTime = block.timestamp;
        _mint(vestingContract, INITIAL_SUPPLY);

        emit VestingStarted(vestingContract);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
