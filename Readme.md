# ROWA Token Contract

This is the official repository for ROWA Token Contract. ROWA is an ERC20-compliant token, built on the Ethereum blockchain, and serves as the sole token for ROWA Platform. It features various functionalities, including burnable, pausable, and snapshot capabilities.

## Tokenomics

- Name: ROWA Token
- Symbol: ROWA
- Decimals: 5
- Initial Supply: 1,000,000,000

## Token Distribution & Vesting

Refer to the token distribution and vesting details provided below.

## Smart Contract

The smart contract is built using Solidity and is based on the OpenZeppelin Contracts library. It inherits from the following contracts:

- ERC20
- ERC20Snapshot
- ERC20Burnable
- ERC20Pausable
- Ownable

## Dependencies

- OpenZeppelin Contracts: [https://github.com/OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

## Setup & Deployment

Before you can deploy the contract, make sure you have installed the required dependencies and configured your environment.

### Prerequisites

- Node.js v12.0.0 or higher
- Hardhat v2.0.0 or higher
- Ganache (Optional, for local development)

### Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/yourusername/rowa-token-contract.git
    ```

2. Change to the project directory:

    ```bash
    cd rowa-token-contract
    ```

3. Install the required dependencies:

    ```bash
    npm install
    ```

4. Configure the `hardhat.config.js` file to connect to your desired Ethereum network.
5. Compile the contract:

    ```bash
    npx hardhat compile
    ```

6. Deploy the contract:

    ```bash
    npx hardhat run --network <network> scripts/deploy.js
    ```

    Replace `<network>` with the desired network name defined in your `hardhat.config.js` file.
    
## Testing

To run the tests, execute the following command:

npx hardhat test
This will run the test suite and display the results in your terminal.

## Contributing

We appreciate contributions from the community. If you would like to contribute, please follow these guidelines:

1. Fork this repository and create a new branch for your feature or bugfix.
2. Develop and test your changes.
3. Make sure your changes adhere to the coding standards and guidelines.
4. Submit a pull request with a detailed description of your changes.

Please note that your pull request may be rejected if it does not meet the quality and coding standards of the project.


# ROWA Vesting Contract

ROWA Vesting Contract is a smart contract deployed on the Polygon network designed to handle the token vesting process for the ROWA project. This contract allows the project to create and manage multiple vesting schedules for different categories of beneficiaries.

## Features

- Customizable vesting schedules for different categories of beneficiaries
- Revocable and non-revocable vesting schedules
- Token release function for beneficiaries to claim their vested tokens
- Revoke function for the contract owner to revoke revocable vesting schedules
- View function to check the vesting schedule details for a beneficiary

## Vesting Schedules

The contract supports the following vesting schedules:

- Public Sale Vesting Schedule: Non-revocable vesting schedule for public sale participants.
- Private Sale Vesting Schedule: Non-revocable vesting schedule for private sale participants.
- Seed Sale Vesting Schedule: Non-revocable vesting schedule for seed sale participants.
- Team Vesting Schedule: Revocable or non-revocable vesting schedule for team members.
- Advisor Vesting Schedule: Revocable or non-revocable vesting schedule for advisors.
- Partnerships Vesting Schedule: Revocable or non-revocable vesting schedule for partnerships.

Each vesting schedule has its own predefined maximum allocation, vesting duration, cliff duration (where applicable), and vesting period.

## Contract Functions

ROWA Vesting Contract provides the following functions:

- `createPublicSaleVesting(address beneficiary_, uint256 amount_)`: Starts Public Sale vesting for a given beneficiary. Can only be called by the contract owner.
- `createPrivateSaleVesting(address beneficiary_, uint256 amount_)`: Starts Private Sale vesting for a given beneficiary. Can only be called by the contract owner.
- `createSeedSaleVesting(address beneficiary_, uint256 amount_)`: Starts Seed Sale vesting for a given beneficiary. Can only be called by the contract owner.
- `createTeamVesting(address beneficiary_, uint256 amount_, bool revokable_)`: Starts Team vesting for a given beneficiary. Can only be called by the contract owner.
- `createAdvisorVesting(address beneficiary_, uint256 amount_, bool revokable_)`: Starts Advisor vesting for a given beneficiary. Can only be called by the contract owner.
- `createPartnershipsVesting(address beneficiary_, uint256 amount_, bool revokable_)`: Starts Partnerships vesting for a given beneficiary. Can only be called by the contract owner.
- `release(address beneficiary, string memory vestingName)`: Releases vested tokens for the beneficiary. Can be called by the beneficiary or anyone else.
- `revoke(address beneficiary, string memory vestingName)`: Revokes a revocable vesting schedule. Can only be called by the contract owner.
- `getVestingSchedule(address beneficiary, string memory vestingName)`: Returns the vesting schedule details for a given beneficiary and vesting type name.
- `getCurrentTime()`: Returns the current time.
- `getInitialVestingAmount(uint256 totalVested, uint256 initialVestingPercentage)`: Returns the initial vesting amount.
- `equal(string memory a, string memory b)`: Compares two strings and returns true if they are equal, otherwise returns false. This function is used internally for comparison purposes.

## Additional Notes

- The vesting schedules are created and managed by the contract owner, ROWA.
- The vesting schedules can be either revocable or non-revocable, depending on the type of vesting and requirements of ROWA.
- Beneficiaries can claim their vested tokens by calling the release  function. The contract calculates the releasable tokens based on the vesting schedule's parameters and the current time.
- The revoke function can be used by the contract owner to revoke a revocable vesting schedule, returning the unvested tokens to the contract owner. It is important to note that non-revocable vesting schedules cannot be revoked.
- The `getVestingSchedule` function allows anyone to query the details of a vesting schedule for a given beneficiary and vesting type name. This can be useful for beneficiaries and third parties to keep track of vesting progress.
- ROWA Vesting Contract is designed to be flexible and can be adapted to the specific needs of ROWA, such as adjusting vesting schedules or allocations as needed.

## Security

If you discover a security vulnerability in this project, please report it privately to the development team. Do not disclose security vulnerabilities publicly.

## License

This project is licensed under the MIT License. Please see the [LICENSE](LICENSE) file for more information.

In summary, ROWA Vesting Contract provides a comprehensive and customizable solution for managing token vesting for ROWA project. By using this smart contract, the project can efficiently distribute tokens to various stakeholders while ensuring a fair and transparent vesting process.


