// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title RowaVesting
 * @author guray.gurkan@creosafe.com
 * @notice Vesting contract for ROWA Token (ROWA) for Value Generation Pool, LP & Staking Rewards, Public Sale, Private Sale, Seed Sale, Initial Liquidity, Reserve, Team, Advisors, Partnerships & Marketing.
 */
contract RowaVesting is Ownable, ReentrancyGuard {
     using SafeERC20 for IERC20; // Use for safe ERC20 interactions.

    uint8 public constant DECIMALS = 5;  // Number of decimal places the token can be divided into.
    uint16 public constant PERCENTAGE_MULTIPLIER = 10_000;  // Used for percentage calculations.

    // Vesting Information for different funds
    // Each fund has a name, total tokens vested, vesting duration, vesting period, initial vesting percentage and an associated address.
    // Some funds also have a freeze  duration, where tokens cannot be withdrawn until after the freeze  period.
    string public constant VGP_VESTING_NAME = "VALUE_GENERATION_POOL";
    uint256 public constant TOTAL_VGP_VESTED =
        360_000_000 * 10 ** uint256(DECIMALS); // Total tokens vested for Value Generation Pool.
    uint256 public totalVGPVested;
    uint256 public constant VGP_VESTING_DURATION = 50 * 30 days; // 50 months vesting duration for Value Generation Pool.
    uint256 public constant VGP_VESTING_PERIOD = 1 * 30 days; // 1 month vesting period for Value Generation Pool.
    uint256 public constant VGP_INITIAL_VESTING_PERCENTAGE = 200; // 2% initial unlock for Value Generation Pool.
    address private immutable _VGP_FUND;

    // Similar vesting information is defined for LP & Staking Rewards, Public Sale, Private Sale, Seed Sale, Initial Liquidity, Reserve, Team, Advisors.
    // Note: The initial vesting percentage refers to the percentage of tokens that are available for withdrawal when vesting starts.
    // For some funds, this is set to 0, meaning no tokens are available for withdrawal when vesting starts.
    // The vesting duration is the total time period over which tokens will be released.
    // The vesting period is the time interval at which tokens will be released.

        
    string public constant LP_VESTING_NAME = "LP_AND_STAKING_REWARDS"; // The name of the vesting program for liquidity providers and staking rewards.
    uint256 public constant TOTAL_LP_VESTED = // The total amount of tokens allocated to the liquidity providers and staking rewards vesting program.
        130_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalLPVested; // The total amount of tokens already vested in the liquidity providers and staking rewards vesting program.
    uint256 public constant LP_VESTING_DURATION = 36 * 30 days; // The duration of the vesting program for liquidity providers and staking rewards.
    uint256 public constant LP_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for liquidity providers and staking rewards.
    uint256 public constant LP_INITIAL_VESTING_PERCENTAGE = 277; // The percentage of tokens initially unlocked for liquidity providers and staking rewards.
    address private immutable _LP_FUND; // The fund address for the liquidity providers and staking rewards vesting program.

    string public constant PS_VESTING_NAME = "PUBLIC_SALE";// The name of the vesting program for public sale.
    uint256 public constant TOTAL_PS_VESTED = // The total amount of tokens allocated to the public sale vesting program.
        70_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalPSVested; // The total amount of tokens already vested in the public sale vesting program.
    uint256 public constant PS_VESTING_DURATION = 4 * 30 days; // The duration of the vesting program for public sale.
    uint256 public constant PS_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for public sale.
    uint256 public constant PS_INITIAL_VESTING_PERCENTAGE = 2500; // The percentage of tokens initially unlocked for public sale.


    string public constant PRIVS_VESTING_NAME = "PRIVATE_SALE"; // The name of the vesting program for private sale.
    uint256 public constant TOTAL_PRIVS_VESTED = // The total amount of tokens allocated to the private sale vesting program.
        40_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalPRIVSVested; // The total amount of tokens already vested in the private sale vesting program.
    uint256 public constant PRIVS_FREEZE_DURATION = 4 * 30 days; // The duration of the freeze  period before vesting starts for private sale.
    uint256 public constant PRIVS_VESTING_DURATION = 12 * 30 days; // The duration of the vesting program for private sale.
    uint256 public constant PRIVS_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for private sale.
    uint256 public constant PRIVS_INITIAL_VESTING_PERCENTAGE = 500; // The percentage of tokens initially unlocked for private sale.


    string public constant SEEDS_VESTING_NAME = "SEED_SALE"; // The name of the vesting program for seed sale.
    uint256 public constant TOTAL_SEEDS_VESTED = // The total amount of tokens allocated to the seed sale vesting program.
        30_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalSEEDSVested; // The total amount of tokens already vested in the seed sale vesting program.
    uint256 public constant SEEDS_FREEZE_DURATION = 4 * 30 days; // The duration of the freeze  period before vesting starts for seed sale.
    uint256 public constant SEEDS_VESTING_DURATION = 12 * 30 days; // The duration of the vesting program for seed sale.
    uint256 public constant SEEDS_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for seed sale.
    uint256 public constant SEEDS_INITIAL_VESTING_PERCENTAGE = 500; // The percentage of tokens initially unlocked for seed sale.


    string public constant LIQ_VESTING_NAME = "INITIAL_LIQUIDITY"; // The name of the vesting program for initial liquidity.
    uint256 public constant TOTAL_LIQ_VESTED = // The total amount of tokens allocated to the initial liquidity vesting program.
        30_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalLIQVested; // The total amount of tokens already vested in the initial liquidity vesting program.
    uint256 public constant LIQ_INITIAL_VESTING_AMOUNT = TOTAL_LIQ_VESTED; // The amount of tokens initially unlocked for initial liquidity.
    uint256 public constant LIQ_INITIAL_VESTING_PERCENTAGE = 10_000; // The percentage of tokens unlocked for initial liquidity.
    address private immutable _LIQ_FUND; // The fund address for the initial liquidity vesting program.


    string public constant RESERVE_VESTING_NAME = "RESERVE"; // The name of the vesting program for reserve.
    uint256 public constant TOTAL_RESERVE_VESTED = // The total amount of tokens allocated to the reserve vesting program.
        50_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalRESERVEVested; // The total amount of tokens already vested in the reserve vesting program.
    uint256 public constant RESERVE_VESTING_DURATION = 5 * 30 days; // The duration of the vesting program for reserve.
    uint256 public constant RESERVE_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for reserve.
    uint256 public constant RESERVE_INITIAL_VESTING_PERCENTAGE = 2_000; // The percentage of tokens initially unlocked for reserve.
    address private immutable _RESERVE_FUND; // The fund address for the reserve vesting program.

    string public constant TEAM_VESTING_NAME = "TEAM"; // The name of the vesting program for team.
    uint256 public constant TOTAL_TEAM_VESTED = // The total amount of tokens allocated to the team vesting program.
        150_000_000 * 10 ** uint256(DECIMALS); 
    uint256 public totalTEAMVested; // The total amount of tokens already vested in the team vesting program.
    uint256 public constant TEAM_VESTING_DURATION = 36 * 30 days; // The duration of the vesting program for the team.
    uint256 public constant TEAM_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for the team.
    uint256 public constant TEAM_INITIAL_VESTING_PERCENTAGE = 0; // The percentage of tokens initially unlocked for the team (0% means no initial unlock).

    string public constant ADVISORS_VESTING_NAME = "ADVISORS"; // The name of the vesting program for advisors.
    uint256 public constant TOTAL_ADVISORS_VESTED = // The total amount of tokens allocated to the advisors vesting program.
        40_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalADVISORSVested; // The total amount of tokens already vested in the advisors vesting program.
    uint256 public constant ADVISORS_VESTING_DURATION = 16 * 30 days; // The duration of the vesting program for advisors.
    uint256 public constant ADVISORS_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for advisors.
    uint256 public ADVISORS_VESTING_AMOUNT = TOTAL_ADVISORS_VESTED / 16; // The amount of tokens vested each period for advisors.
    uint256 public constant ADVISORS_INITIAL_VESTING_PERCENTAGE = 0; // The percentage of tokens initially unlocked for advisors (0% means no initial unlock).


    
    string public constant PARTNERSHIPS_VESTING_NAME = // The name of the vesting program for partnerships and marketing.
        "PARTNERSHIPS_AND_MARKETING";
    uint256 public constant TOTAL_PARTNERSHIPS_VESTED = // The total amount of tokens allocated to the partnerships and marketing vesting program.
        100_000_000 * 10 ** uint256(DECIMALS);
    uint256 public totalPARTNERSHIPSVested; // The total amount of tokens already vested in the partnerships and marketing vesting program.
    uint256 public constant PARTNERSHIPS_VESTING_DURATION = 5 * 30 days; // The duration of the vesting program for partnerships and marketing.
    uint256 public constant PARTNERSHIPS_VESTING_PERIOD = 1 * 30 days; // The period between each vesting event for partnerships and marketing.
    uint256 public constant PARTNERSHIPS_INITIAL_VESTING_PERCENTAGE = 2_000; // The percentage of tokens initially unlocked for partnerships and marketing.

    
    IERC20 private immutable _token; // The address of the ERC20 token managed by this contract.


    /**
     * @dev Struct for the vesting schedule of a token holder. A vesting schedule is a sequence of slices of tokens that are released to the beneficiary progressively over time.
     * The amount of tokens released at each slice is calculated from the vesting schedule parameters.
     * The vesting schedule parameters are immutable once the vesting schedule is created.
     */
    struct VestingSchedule {
        bool initialized; // whether or not the vesting has been initialized
        string name; // name of the vesting schedule
        address beneficiary; // beneficiary of tokens after they are released
        uint256 start; // start time of the vesting period
        uint256 duration; // duration of the vesting period in seconds
        uint256 period; // period in seconds between slices
        uint256 amountTotal; // total amount of tokens to be released at the end of the vesting
        uint256 amountReleased; // amount of tokens released until now
        uint256 amountInitial; // amount of tokens to be released at the start of the vesting
        bool revoked; // whether or not the vesting has been revoked
        bool revokable; // revokable flag
    }

 bytes32[] private vestingSchedulesIds; // An array of identifiers for the vesting schedules.
    
    mapping(bytes32 => VestingSchedule) private vestingSchedules; // A mapping from vesting schedule identifiers to the actual VestingSchedule structures.
    uint256 private vestingSchedulesTotalAmount; // The total amount of tokens across all vesting schedules.
    mapping(address => uint256) private holdersVestingCount; // A mapping from token holder addresses to the count of their vesting schedules.


event Released(uint256 amount); // An event that is emitted when tokens are released from a vesting schedule.
    event Revoked(bytes32 vestingScheduleId); // An event that is emitted when a vesting schedule is revoked.
    
    // An event that is emitted when a vesting schedule is created for each different group.
    event VGPVestingScheduleCreated();
    event LPVestingScheduleCreated();
    event LiqVestingScheduleCreated();
    event ReserveVestingScheduleCreated();
    event PublicSaleVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );
    event SeedSaleVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );
    event TeamVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );
    event AdvisorsVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );
    event PartnershipsVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );
    event PrivateSaleVestingScheduleCreated(
        address indexed beneficiary,
        uint256 amountTotal
    );

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     * @param vestingScheduleId Identifier of the vesting schedule.
     */

     // A modifier that checks if the vesting schedule is active (exists and is not revoked).
    modifier onlyActive(bytes32 vestingScheduleId) {
        require(
            vestingSchedules[vestingScheduleId].initialized,
            "Vesting schedule not initialized"
        );
        require(
            !vestingSchedules[vestingScheduleId].revoked,
            "Vesting schedule revoked"
        );
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     * @param VGP_FUND_ address of the VGP fund
     * @param LP_FUND_ address of the LP fund
     * @param LIQ_FUND_ address of the LIQ fund
     * @param RESERVE_FUND_ address of the RESERVE fund
     */
        // Constructor of the contract. It initializes the contract with the addresses of the token and several funds.
    constructor(
        address token_, // Address of the ERC20 token
        address VGP_FUND_, // Address of the VGP fund
        address LP_FUND_, // Address of the LP fund
        address LIQ_FUND_, // Address of the LIQ fund
        address RESERVE_FUND_ // Address of the RESERVE fund
    ) {
        require(token_ != address(0x0), "Token address cannot be 0");
        require(VGP_FUND_ != address(0x0), "VGP_FUND address cannot be 0");
        require(LP_FUND_ != address(0x0), "LP_FUND address cannot be 0");
        require(LIQ_FUND_ != address(0x0), "LIQ_FUND address cannot be 0");
        require(
            RESERVE_FUND_ != address(0x0),
            "RESERVE_FUND address cannot be 0"
        );
        _token = IERC20(token_);
        _VGP_FUND = VGP_FUND_;
        _LP_FUND = LP_FUND_;
        _LIQ_FUND = LIQ_FUND_;
        _RESERVE_FUND = RESERVE_FUND_;
    }

    /**
     * @notice Revokes the vesting schedule for given identifier.
     * @param vestingScheduleId the vesting schedule identifier
     */
    function revoke(
        bytes32 vestingScheduleId
    ) 
    // Accessible only by the contract owner and if the vesting schedule is active
    external onlyOwner onlyActive(vestingScheduleId) {
                // Retrieves the vesting schedule from the mapping

        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
                // Ensures the vesting schedule can be revoked

        require(
            vestingSchedule.revokable == true,
            "TokenVesting: vesting is not revocable"
        );
                // Computes the amount of tokens that can be released

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
                    // If there is an amount to be released, it releases it

            release(vestingScheduleId, vestedAmount);
        }
                // Calculates the amount of tokens that are not yet released

        uint256 unreleased = vestingSchedule.amountTotal -
            vestingSchedule.amountReleased;
        // Updates the total amount of tokens that are in vesting schedules

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;
        // Depending on the name of the vesting schedule, it updates the total amount of tokens vested for that type
        // Note: `equal` is a function that compares strings.
        if (equal(vestingSchedule.name, TEAM_VESTING_NAME)) {
            totalTEAMVested = totalTEAMVested - unreleased;
        }
        if (equal(vestingSchedule.name, ADVISORS_VESTING_NAME)) {
            totalADVISORSVested = totalADVISORSVested - unreleased;
        }
        if (equal(vestingSchedule.name, PARTNERSHIPS_VESTING_NAME)) {
            totalPARTNERSHIPSVested = totalPARTNERSHIPSVested - unreleased;
        }
        // Marks the vesting schedule as revoked

        vestingSchedule.revoked = true;
        // Emits an event to indicate the vesting schedule has been revoked

        emit Revoked(vestingScheduleId);
    }

    /**
     * @dev Starts vgp token vesting for _VGP_FUND address.
     */
    function startVGPVesting() external onlyOwner {
        require(totalVGPVested == 0, "VGP vesting already started");

        _createVestingSchedule(
            _VGP_FUND,
            VGP_VESTING_NAME,
            block.timestamp,
            VGP_VESTING_DURATION,
            VGP_VESTING_PERIOD,
            TOTAL_VGP_VESTED,
            getInitialVestingAmount(
                TOTAL_VGP_VESTED,
                VGP_INITIAL_VESTING_PERCENTAGE
            ),
            false
        );

        totalVGPVested = totalVGPVested + TOTAL_VGP_VESTED;

        emit VGPVestingScheduleCreated();
    }

    /**
     * @dev Starts lp token vesting for _LP_FUND address.
     */
    function startLPVesting() external onlyOwner {
        require(totalLPVested == 0, "LP vesting already started");

        _createVestingSchedule(
            _LP_FUND,
            LP_VESTING_NAME,
            block.timestamp,
            LP_VESTING_DURATION,
            LP_VESTING_PERIOD,
            TOTAL_LP_VESTED,
            getInitialVestingAmount(
                TOTAL_LP_VESTED,
                LP_INITIAL_VESTING_PERCENTAGE
            ),
            false
        );

        totalLPVested = totalLPVested + TOTAL_LP_VESTED;

        emit LPVestingScheduleCreated();
    }

    /**
     * @dev Starts liq token vesting for _LIQ_FUND address.
     */
    function startLiqVesting() external onlyOwner {
        require(totalLIQVested == 0, "Liq vesting already started");

        _createVestingSchedule(
            _LIQ_FUND,
            LIQ_VESTING_NAME,
            block.timestamp,
            0,
            0,
            TOTAL_LIQ_VESTED,
            getInitialVestingAmount(
                TOTAL_LIQ_VESTED,
                LIQ_INITIAL_VESTING_PERCENTAGE
            ),
            false
        );

        totalLIQVested = totalLIQVested + TOTAL_LIQ_VESTED;

        emit LiqVestingScheduleCreated();
    }

    /**
     * @dev Starts reserve vesting for _RESERVE_FUND address.
     */
    function startReserveVesting() external onlyOwner {
        require(totalRESERVEVested == 0, "Reserve vesting already started");

        _createVestingSchedule(
            _RESERVE_FUND,
            RESERVE_VESTING_NAME,
            block.timestamp,
            RESERVE_VESTING_DURATION,
            RESERVE_VESTING_PERIOD,
            TOTAL_RESERVE_VESTED,
            getInitialVestingAmount(
                TOTAL_RESERVE_VESTED,
                RESERVE_INITIAL_VESTING_PERCENTAGE
            ),
            false
        );

        totalRESERVEVested = totalRESERVEVested + TOTAL_RESERVE_VESTED;

        emit ReserveVestingScheduleCreated();
    }

    /**
     * @dev Starts Public sale vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @notice revokable is set to false for public sale vesting as it is not possible to revoke tokens that have already been sold
     */
    function createPublicSaleVesting(
        address beneficiary_,
        uint256 amount_
    ) external onlyOwner {
        require(
            totalPSVested + amount_ <= TOTAL_PS_VESTED,
            "Public sale vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            PS_VESTING_NAME,
            block.timestamp,
            PS_VESTING_DURATION,
            PS_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(amount_, PS_INITIAL_VESTING_PERCENTAGE),
            false
        );

        totalPSVested = totalPSVested + amount_;

        emit PublicSaleVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @dev Starts private sale token vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @notice revokable is set to false for private sale vesting as it is not possible to revoke tokens that have already been sold
     */
    function createPrivateSaleVesting(
        address beneficiary_,
        uint256 amount_
    ) external onlyOwner {
        require(
            totalPRIVSVested + amount_ <= TOTAL_PRIVS_VESTED,
            "Private sale vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            PRIVS_VESTING_NAME,
            block.timestamp + PRIVS_FREEZE_DURATION,
            PRIVS_VESTING_DURATION,
            PRIVS_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(amount_, PRIVS_INITIAL_VESTING_PERCENTAGE),
            false
        );

        totalPRIVSVested = totalPRIVSVested + amount_;

        emit PrivateSaleVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @dev Starts seed sale token vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @notice revokable is set to false for seed sale vesting as it is not possible to revoke tokens that have already been sold
     */
    function createSeedSaleVesting(
        address beneficiary_,
        uint256 amount_
    ) external onlyOwner {
        require(
            totalSEEDSVested + amount_ <= TOTAL_SEEDS_VESTED,
            "Seed sale vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            SEEDS_VESTING_NAME,
            block.timestamp + SEEDS_FREEZE_DURATION,
            SEEDS_VESTING_DURATION,
            SEEDS_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(amount_, SEEDS_INITIAL_VESTING_PERCENTAGE),
            false
        );

        totalSEEDSVested = totalSEEDSVested + amount_;

        emit SeedSaleVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @dev Starts team vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @param revokable_ whether the vesting is revocable or not
     */
    function createTeamVesting(
        address beneficiary_,
        uint256 amount_,
        bool revokable_
    ) external onlyOwner {
        require(
            totalTEAMVested + amount_ <= TOTAL_TEAM_VESTED,
            "Team vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            TEAM_VESTING_NAME,
            block.timestamp,
            TEAM_VESTING_DURATION,
            TEAM_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(amount_, TEAM_INITIAL_VESTING_PERCENTAGE),
            revokable_
        );

        totalTEAMVested = totalTEAMVested + amount_;

        emit TeamVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @dev Starts advisor vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @param revokable_ whether the vesting is revocable or not
     */
    function createAdvisorVesting(
        address beneficiary_,
        uint256 amount_,
        bool revokable_
    ) external onlyOwner {
        require(
            totalADVISORSVested + amount_ <= TOTAL_ADVISORS_VESTED,
            "Advisor vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            ADVISORS_VESTING_NAME,
            block.timestamp,
            ADVISORS_VESTING_DURATION,
            ADVISORS_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(
                amount_,
                ADVISORS_INITIAL_VESTING_PERCENTAGE
            ),
            revokable_
        );

        totalADVISORSVested = totalADVISORSVested + amount_;

        emit AdvisorsVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @dev Starts partnerships vesting for a given beneficiary.
     * @param beneficiary_ the beneficiary of the tokens
     * @param amount_ the amount of tokens to be vested
     * @param revokable_ whether the vesting is revocable or not
     */
    function createPartnershipsVesting(
        address beneficiary_,
        uint256 amount_,
        bool revokable_
    ) external onlyOwner {
        require(
            totalPARTNERSHIPSVested + amount_ <= TOTAL_PARTNERSHIPS_VESTED,
            "Partnerships vesting amount exceeds total amount"
        );

        _createVestingSchedule(
            beneficiary_,
            PARTNERSHIPS_VESTING_NAME,
            block.timestamp,
            PARTNERSHIPS_VESTING_DURATION,
            PARTNERSHIPS_VESTING_PERIOD,
            amount_,
            getInitialVestingAmount(
                amount_,
                PARTNERSHIPS_INITIAL_VESTING_PERCENTAGE
            ),
            revokable_
        );

        totalPARTNERSHIPSVested = totalPARTNERSHIPSVested + amount_;

        emit PartnershipsVestingScheduleCreated(beneficiary_, amount_);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @param vestingScheduleId the vesting schedule identifier
     * @return the vested amount
     */
    function computeReleasableAmount(
        bytes32 vestingScheduleId
    ) external view onlyActive(vestingScheduleId) returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     * @param holder address of the vesting beneficiary
     */
    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory) {
        return
            vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(
                    holder,
                    holdersVestingCount[holder] - 1
                )
            ];
    }

    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @param _beneficiary address of the vesting beneficiary
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @param index index of the vesting schedule in the vestings mapping
     * @return the vesting id
     */
    function getVestingIdAtIndex(
        uint256 index
    ) external view returns (bytes32) {
        require(
            index < getVestingSchedulesCount(),
            "TokenVesting: index out of bounds"
        );
        return vestingSchedulesIds[index];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @param holder address of the vesting beneficiary
     * @param index index of the vesting schedule in the vestings mapping
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(holder, index)
            );
    }

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getTokenAddress() external view returns (address) {
        return address(_token);
    }

    /**
     * @notice Release vested amount of tokens.
     * @param vestingScheduleId the vesting schedule identifier
     * @param amount the amount to release
     */
    function release(
        bytes32 vestingScheduleId,
        uint256 amount
    ) public nonReentrant onlyActive(vestingScheduleId) { // The function is public and can be called externally. The nonReentrant modifier is used to prevent re-entrant attacks. The onlyActive modifier is presumably used to check if the vesting schedule is active.
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ]; // Load the vesting schedule from storage using the provided vesting schedule ID.
        
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary; // Check if the caller of the function (msg.sender) is the beneficiary of the vesting schedule.
        bool isOwner = msg.sender == owner();// Check if the caller of the function (msg.sender) is the owner of the contract.

         // The function can only be called by the beneficiary of the vesting schedule or the owner of the contract.
        require(
            isBeneficiary || isOwner,
            "TokenVesting: only beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);// Compute the amount of tokens that can be released at this point in time according to the vesting schedule.
        
        // The amount of tokens to be released must be less than or equal to the amount of tokens that have vested.
        require(
            vestedAmount >= amount,
            "TokenVesting: cannot release tokens, not enough vested tokens"
        );
        vestingSchedule.amountReleased =
            vestingSchedule.amountReleased +
            amount; // Update the amount of tokens that have been released according to the vesting schedule.
        address beneficiary = vestingSchedule.beneficiary;// Get the beneficiary's address.
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount; // Subtract the amount of tokens to be released from the total amount of tokens to be vested.
        _token.safeTransfer(beneficiary, amount);// Safely transfer the tokens to the beneficiary.

        emit Released(amount); // Emit an event that indicates the amount of tokens that have been released.
    }

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @param vestingScheduleId the vesting schedule identifier
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        bytes32 vestingScheduleId
    ) public view returns (VestingSchedule memory) {
        return vestingSchedules[vestingScheduleId];
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     * @param holder address of the vesting beneficiary
     * @return vesting schedule identifier for the next vesting schedule for the holder address
     */
    function computeNextVestingScheduleIdForHolder(
        address holder
    ) public view returns (bytes32) {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder]
            );
    }

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     * @param holder address of the vesting beneficiary
     * @param index the index of the vesting schedule for the holder
     * @return schedule identifier for the specified vesting schedule
     */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(holder, index));
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @param vestingSchedule the VestingSchedule for which the releasable amount will be calculated
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        

        // If the initial vesting amount hasn't been fully released yet, release the remainder of it
        if (block.timestamp < vestingSchedule.start && vestingSchedule.amountReleased < vestingSchedule.amountInitial) {
            return
                vestingSchedule.amountInitial - vestingSchedule.amountReleased;
        }

        // If all tokens have already been released, no more tokens can be released
        if (vestingSchedule.amountReleased >= vestingSchedule.amountTotal) {
            return 0;
        }
        //If vesting schedule duration has elapsed, return the remaining releasable amount
        if (block.timestamp >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.amountReleased;
        }

        uint256 timeFromStart = block.timestamp - vestingSchedule.start; // Calculate the elapsed time since the start of the vesting period
        uint secondsPerSlice = vestingSchedule.period;// Get the duration of each vesting slice in seconds
        uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;// Calculate the number of fully vested periods
        uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;// Calculate the total number of seconds vested
        uint256 vestedAmount = (vestingSchedule.amountTotal - vestingSchedule.amountInitial) * vestedSeconds;// Calculate the vested amount proportional to total time

        // Normalize the vested amount to the vesting duration and add the initial vested amount
        vestedAmount = (vestedAmount / vestingSchedule.duration) + vestingSchedule.amountInitial;
        vestedAmount = vestedAmount - vestingSchedule.amountReleased;
        // Return the releasable amount

        return vestedAmount;
    }

    /**
     * @dev Returns initial vesting amount.
     * @param totalVested total vesting amount
     * @param initialVestingPercentage the percentage of initial vesting 
     * @return the initial vesting amount
     */
    function getInitialVestingAmount(
        uint256 totalVested,
        uint256 initialVestingPercentage
    ) internal pure returns (uint256) {
        return (totalVested * initialVestingPercentage) / PERCENTAGE_MULTIPLIER;
    }

    /**
     * @dev Returns true if the two strings are equal.
     * @param a first string to be compared
     * @param b second string to be compared
     * @return boolean whether the two strings are equal
     */
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /**
     * @dev create a vesting schedule for a beneficiary. It is meant to be called by the owner and internally.
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param name_ name of the vesting schedule
     * @param start_ the time (as Unix time) at which point vesting starts
     * @param duration_ duration in seconds of the period in which the tokens will vest
     * @param slicePeriodSeconds_ period in seconds between slices
     * @param amount_ total amount of tokens to be vested
     * @param amountInitial_ amount of tokens to be released at the start of the vesting
     * @param revokable_ whether the vesting is revokable or not
     * @return the vesting schedule structure information
     */
    function _createVestingSchedule(
        address beneficiary_,
        string memory name_,
        uint256 start_,
        uint256 duration_,
        uint256 slicePeriodSeconds_,
        uint256 amount_,
        uint256 amountInitial_,
        bool revokable_
    ) private returns (bytes32) {
                // Ensure there are enough tokens available to be vested

        require(
            this.getWithdrawableAmount() >= amount_,
            "TokenVesting: cannot create vesting schedule because not sufficient tokens"
        );
                // Calculate the ID for the new vesting schedule

        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            beneficiary_
        );
        // Create a new vesting schedule with the provided parameters and store it in the vestingSchedules mapping
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            name_,
            beneficiary_,
            start_,
            duration_,
            slicePeriodSeconds_,
            amount_,
            0,
            amountInitial_,
            false,
            revokable_
        );

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + amount_;// Increase the total amount of tokens to be vested by the amount of the new vesting schedule
        vestingSchedulesIds.push(vestingScheduleId); // Add the new vesting schedule ID to the array of vesting schedule IDs
        uint256 currentVestingCount = holdersVestingCount[beneficiary_];// Increase the count of vesting schedules for the beneficiary
        holdersVestingCount[beneficiary_] = currentVestingCount + 1;// Return the ID of the new vesting schedule

        return vestingScheduleId;
    }
}
