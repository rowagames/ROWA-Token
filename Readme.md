# ROWA Token Contract

This is the official repository for the ROWA Token Contract. ROWA is an ERC20-compliant token, built on the Ethereum blockchain, and serves as the sole token for the ROWA Platform. It features various functionalities, including burnable, pausable, and snapshot capabilities.

## Tokenomics

- Name: ROWA Token
- Symbol: ROWA
- Decimals: 5
- Initial Supply: 1,000,000,000

## Token Distribution & Vesting

Refer to the token distribution and vesting details provided in the original question.

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

## Security

If you discover a security vulnerability in this project, please report it privately to the development team. Do not disclose security vulnerabilities publicly.

## License

This project is licensed under the MIT License. Please see the [LICENSE](LICENSE) file for more information.
