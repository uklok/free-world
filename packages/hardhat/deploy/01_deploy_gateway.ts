import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ChainLinkNetworkUserConfig } from "../interfaces";

/**
 * Deploys a contract named "FWGateway" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const contractName = "FWGateway";
// const CLIENTS = []; // List of contract names to be registered in the gateway as clients.
// const ALLOWED_REQUESTS = []; // List of requests to be allowed by the gateway.

class MissingFunctionsConfig extends Error {
  constructor(network: string) {
    super(`Missing DON 'functions' config in hardhat.config.ts for network: ${network}`);
    this.name = "ErrorMissingFunctionsConfig";
  }
}

class WrongFunctionsConfig extends Error {
  constructor(network: string) {
    super(`Missing router or donId in hardhat.config.ts for network: ${network}`);
    this.name = "ErrorWrongFunctionsConfig";
  }
}

const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { name, config } = hre.network;
  if (!("functions" in config)) throw new MissingFunctionsConfig(name);

  const {
    functions: {
      router,
      donId: { onChain: donId },
    },
  } = config as ChainLinkNetworkUserConfig;
  if (!router || !donId) throw new WrongFunctionsConfig(name);

  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  console.log(`network: ${name} | router:${router} | donId:${donId}`);
  await deploy(contractName, {
    from: deployer,
    // Contract constructor arguments
    args: [router, donId, deployer],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // TODO: Register clients to the gateway.
  // TODO: Register allowed requests.
  // const Gateway = await hre.ethers.getContract(contractName, deployer);
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags FWGateway
deployYourContract.tags = [contractName];
