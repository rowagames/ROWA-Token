import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  paths: {
    tests: "test",
  },
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/1e81671a8d2143219012184c6c063937",
      chainId: 80001,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.19",
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
