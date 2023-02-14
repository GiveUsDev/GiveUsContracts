import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'solidity-coverage';
import 'hardhat-abi-exporter';
import 'hardhat-gas-reporter';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {enabled: true}
    }
  },
  abiExporter: {
    path: './src/abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: true
  },
  gasReporter: {
    enabled: true
  }
};

export default config;
