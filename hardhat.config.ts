import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

console.log(process.env.PRIVATE_KEY);
const config: HardhatUserConfig = {
  solidity: "0.8.26",
  networks: {
    hardhat: {},
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.SEPOLIA_PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    baseTestnet: {
      url: `https://base-goerli.infura.io/v3/${process.env.BASE_TESTNET_PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    base: {
      url: `https://base-mainnet.infura.io/v3/${process.env.BASE_PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
};
export default config;
