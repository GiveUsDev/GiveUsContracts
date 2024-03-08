import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'solidity-coverage';
import 'hardhat-abi-exporter';
import 'hardhat-gas-reporter';
import '@openzeppelin/hardhat-upgrades';
const dotenv = require('dotenv');
dotenv.config();


const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY as string]
    }
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {enabled: true}
    }
  },
  defender: {
    apiKey: process.env.DEFENDER_KEY as string,
    apiSecret: process.env.DEFENDER_SECRET as string,
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
