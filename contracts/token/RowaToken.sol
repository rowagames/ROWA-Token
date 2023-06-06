// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Importing required contracts from OpenZeppelin, a library for secure smart contract development.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  // Basic ERC20 functionality.
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";  // Enables creation of snapshots for token balances.
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";  // Allows token holders to destroy their own tokens.
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";  // Allows pausing of token transfers.
import "@openzeppelin/contracts/access/Ownable.sol";  // Provides basic authorization control functions.

/**
 * @title RowaToken
 * @author guraygrkn@gmail.com
 * @notice This contract implements an ERC20 token with additional features. The token has burnable, pausable, 
 * and snapshot capabilities. It also includes a vesting schedule.
 */
contract RowaToken is
    ERC20,
    ERC20Snapshot,
    ERC20Burnable,
    ERC20Pausable,
    Ownable
{
    address public vestingContract;  // Address of the vesting contract.

    // Token Information
    string public constant NAME = "ROWA Token";  // Name of the token.
    string public constant SYMBOL = "ROWA";  // Symbol of the token.
    uint8 public constant DECIMALS = 5;  // Number of decimal places the token can be divided into.
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** uint256(DECIMALS);  // Initial supply of tokens.

    // start time
    uint256 public startTime;  // Time when vesting starts.

    // Events that notify when certain state changes happen on the blockchain.
    event ContractPaused();  // Emitted when the contract is paused.
    event ContractUnpaused();  // Emitted when the contract is unpaused.
    event SnapshotCreated(uint256 id);  // Emitted when a snapshot is created.
    event VestingStarted(address vestingContract);  // Emitted when vesting starts.

    // Constructor sets the name and symbol of the token.
    constructor() ERC20(NAME, SYMBOL) {}

    // Function to create a snapshot,  can only be called by the owner.
    function snapshot() external onlyOwner {
        _snapshot();

        emit SnapshotCreated(_getCurrentSnapshotId());
    }

    // Function to pause token transfers,  can only be called by the owner.
    function pause() external onlyOwner {
        _pause();

        emit ContractPaused();
    }

    // Function to unpause token transfers,  can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();

        emit ContractUnpaused();
    }

    // Function to start vesting, can only be called by the owner.
    function startVesting(address _vestingContract) external onlyOwner {
        require(_vestingContract != address(0), "ROWAToken: vesting contract is the zero address");
        require(startTime == 0, "ROWAToken: vesting already started");
        vestingContract = _vestingContract;

        startTime = block.timestamp;
        _mint(vestingContract, INITIAL_SUPPLY);

        emit VestingStarted(vestingContract);
    }

    // Hook that is called before any transfer of tokens.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Overrides the decimals function in ERC20 to set a constant number of decimals.
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
