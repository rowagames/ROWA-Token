import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";
import fs from "fs";

const privateKey = fs.readFileSync(".secret").toString().trim();

const config: HardhatUserConfig = {
  paths: {
    tests: "test",
  },
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/1e81671a8d2143219012184c6c063937",
      chainId: 80001,
      accounts: [privateKey],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
    ],
  },
};

export default config;
