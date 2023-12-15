// import { config as envConfig } from "@chainlink/env-enc";
import { config as envConfig } from "dotenv";
envConfig();

import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

import { ChainLinkUserConfig } from "./interfaces";

// If not set, it uses ours Alchemy's default API key.
// You can get your own at https://dashboard.alchemyapi.io
const providerApiKey = process.env.ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF";
// If not set, it uses the hardhat account 0 private key.
const deployerPrivateKey =
  process.env.DEPLOYER_PRIVATE_KEY ?? "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
// If not set, it uses ours Etherscan default API key.
const etherscanApiKey = process.env.ETHERSCAN_API_KEY || "DNXJA8RX2Q3VZ4URQIWP7Z68CJXQZSC6AW";

const config: ChainLinkUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        // https://docs.soliditylang.org/en/latest/using-the-compiler.html#optimizer-options
        runs: 200,
      },
    },
  },
  defaultNetwork: "localhost",
  namedAccounts: {
    deployer: {
      // By default, it will take the first Hardhat account as the deployer
      default: 0,
    },
  },
  networks: {
    // View the networks that are pre-configured.
    // If the network you are looking for is not here you can add new network settings
    localhost: {
      functions: {
        // fill with your local router address
        router: "0x0000000000000000000000000000000000000000",
        donId: {
          // fill with your local donId
          onChain: "0x0000000000000000000000000000000000000000000000000000000000000000",
          offChain: "fun-ethereum-local-1",
        },
      },
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${providerApiKey}`,
        enabled: process.env.MAINNET_FORKING_ENABLED === "true",
      },
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0x65Dcc24F8ff9e51F10DCc7Ed1e4e2A61e6E14bd6",
        donId: {
          onChain: "0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000",
          offChain: "fun-ethereum-mainnet-1",
        },
      },
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0",
        donId: {
          onChain: "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000",
          offChain: "fun-ethereum-sepolia-1",
        },
      },
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    arbitrumGoerli: {
      url: `https://arb-goerli.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    optimism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    optimismGoerli: {
      url: `https://opt-goerli.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygon: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0xdc2AAF042Aeff2E68B3e8E33F19e4B9fA7C73F10",
        donId: {
          onChain: "0x66756e2d706f6c79676f6e2d6d61696e6e65742d310000000000000000000000",
          offChain: "fun-polygon-mainnet-1",
        },
      },
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C",
        donId: {
          onChain: "0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000",
          offChain: "fun-polygon-mumbai-1",
        },
      },
    },
    polygonZkEvm: {
      url: `https://polygonzkevm-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygonZkEvmTestnet: {
      url: `https://polygonzkevm-testnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    zkSyncTestnet: {
      url: "https://testnet.era.zksync.dev",
      zksync: true,
      accounts: [deployerPrivateKey],
      verifyURL: "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
    },
    zkSync: {
      url: "https://mainnet.era.zksync.io",
      zksync: true,
      accounts: [deployerPrivateKey],
      verifyURL: "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
    },
    gnosis: {
      url: "https://rpc.gnosischain.com",
      accounts: [deployerPrivateKey],
    },
    chiado: {
      url: "https://rpc.chiadochain.net",
      accounts: [deployerPrivateKey],
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [deployerPrivateKey],
    },
    baseGoerli: {
      url: "https://goerli.base.org",
      accounts: [deployerPrivateKey],
    },
    scrollSepolia: {
      url: "https://sepolia-rpc.scroll.io",
      accounts: [deployerPrivateKey],
    },
    scroll: {
      url: "https://rpc.scroll.io",
      accounts: [deployerPrivateKey],
    },
    pgn: {
      url: "https://rpc.publicgoods.network",
      accounts: [deployerPrivateKey],
    },
    pgnTestnet: {
      url: "https://sepolia.publicgoods.network",
      accounts: [deployerPrivateKey],
    },
    axax: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43114,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0x9f82a6A0758517FD0AfA463820F586999AF314a0",
        donId: {
          onChain: "0x66756e2d6176616c616e6368652d6d61696e6e65742d31000000000000000000",
          offChain: "fun-avalanche-mainnet-1",
        },
      },
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: [deployerPrivateKey],
      functions: {
        router: "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0",
        donId: {
          onChain: "0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000",
          offChain: "fun-avalanche-fuji-1",
        },
      },
    },
  },
  verify: {
    etherscan: {
      apiKey: `${etherscanApiKey}`,
    },
  },
};

export default config;
