import { HardhatUserConfig, HttpNetworkUserConfig, NetworksUserConfig, NetworkUserConfig } from "hardhat/types";

export interface ChainLinkFunctionsConfig {
  donId: { onChain: string; offChain: string };
  router: string;
}

export interface ChainLinkNetworkUserConfig extends HttpNetworkUserConfig {
  functions?: ChainLinkFunctionsConfig;
}

export interface ChainLinkNetworksUserConfig extends NetworksUserConfig {
  [networkName: string]: NetworkUserConfig | ChainLinkNetworkUserConfig | undefined;
}

export interface ChainLinkUserConfig extends Omit<HardhatUserConfig, "networks"> {
  networks?: ChainLinkNetworksUserConfig;
}
