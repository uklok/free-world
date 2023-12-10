import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

/**
 * Deploys a contract named "FreeWorld" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Deploy the registry contract
  await deploy("FreeWorldUserRegistry", {
    from: deployer,
    // Contract constructor arguments
    args: [deployer],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  const UserRegistry = await hre.ethers.getContract("FreeWorldUserRegistry", deployer);
  const verifierRole = await UserRegistry.VERIFIER_ROLE();
  console.log("FreeWorldUserRegistry contract deployed | ", UserRegistry.address);

  await deploy("FreeWorld", {
    from: deployer,
    // Contract constructor arguments
    args: [deployer, UserRegistry.address],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract
  const FreeWorld = await hre.ethers.getContract("FreeWorld");
  console.log("FreeWorld contract deployed | ", FreeWorld.address);

  const contractAddress = FreeWorld.address;
  let isVerifier = await UserRegistry.hasRole(verifierRole, contractAddress);
  if (!isVerifier) {
    console.log(`Main contract ${contractAddress} has VERIFIER_ROLE:${isVerifier} in registry contract`);

    // Grant the main contract as VERIFIER_ROLE in registry contract
    const tx = await UserRegistry.grantRole(verifierRole, contractAddress);
    await tx.wait();

    isVerifier = await UserRegistry.hasRole(verifierRole, contractAddress);
    console.log(`Main contract ${contractAddress} has VERIFIER_ROLE:${isVerifier} in registry contract`);
  }
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["FreeWorld"];
