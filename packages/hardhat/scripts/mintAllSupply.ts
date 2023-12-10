import * as dotenv from "dotenv";
dotenv.config();
import hre, { ethers } from "hardhat";
import { BigNumber } from "ethers";
import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

const rl = readline.createInterface({ input, output });

const localProviderUrl = "http://127.0.0.1:8545/";
const provider = new ethers.providers.JsonRpcProvider(localProviderUrl);
const toEther = (value: BigNumber): number => Number(ethers.utils.formatEther(value));
const ETHER = ethers.utils.parseEther("1");
const gasLimit = 110000;
const MAX_ATTEMPTS = 3;
const RETRY_DELAY = 1000;

async function main() {
  const faucets = await ethers.getSigners();
  const getBalance = async (address: any) => provider.getBalance(address);
  const freeWorld = await hre.ethers.getContract("FreeWorld");
  const symbol = await freeWorld.symbol();

  const maxSupply = toEther(await freeWorld.MAX_SUPPLY());
  const maxMintAmount = toEther(await freeWorld.MAX_SUPPLY_PER_MINT());
  const minMintAmount = toEther(await freeWorld.MIN_SUPPLY_PER_MINT());
  const weiMintPrice = await freeWorld.MINT_PRICE();
  const mintPrice = toEther(weiMintPrice);
  const totalMinted = toEther(await freeWorld.totalMinted());

  const remainingSupply = maxSupply - totalMinted;
  let mintPerFaucet = remainingSupply / faucets.length;

  // if the faucet mint amount is less than the minimum mint amount, compute max faucets to use in order to reach the minimum mint amount
  if (mintPerFaucet < minMintAmount) {
    const maxFaucets = Math.floor(minMintAmount / mintPerFaucet);
    console.log(`Mint per faucet (${mintPerFaucet}) is less than the minimum mint amount (${minMintAmount})!`);
    console.log(`Using ${maxFaucets} faucets to reach the minimum mint amount!`);
    faucets.splice(maxFaucets);
    // recompute the mint per faucet
    mintPerFaucet = remainingSupply / faucets.length;
  }

  const faucetMintCost = toEther(weiMintPrice.mul(ethers.utils.parseEther(mintPerFaucet.toString())).div(ETHER));

  console.log("FreeWorld address:", freeWorld.address);
  console.log("FreeWorld maxSupply:", maxSupply);
  console.log("FreeWorld mintPrice:", mintPrice);
  console.log("FreeWorld maxMintAmount:", maxMintAmount);
  console.log("FreeWorld totalMinted:", totalMinted);
  console.log("FreeWorld remainingSupply:", remainingSupply);
  console.log("FreeWorld mint per faucet:", mintPerFaucet);
  console.log("Faucet mint cost:", faucetMintCost);

  const answer = await rl.question("Do you want to continue? (y/N)");

  if (answer !== "y") {
    console.log("Aborting...");
    process.exit(0);
  }

  console.log("Starting faucets minting...");
  return Promise.all(
    faucets.map(async faucet => {
      const address = faucet.address;
      const balance = toEther(await getBalance(address));
      const nTx = Math.ceil(mintPerFaucet / maxMintAmount);

      let totalMint = mintPerFaucet;
      const amounts = Array.from({ length: nTx }, () => maxMintAmount);
      amounts.forEach((amount, i) => {
        amounts[i] = Math.min(totalMint, maxMintAmount);
        totalMint -= maxMintAmount;
      });

      const connection = freeWorld.connect(faucet);
      console.log(`Starting minting from ${address}... | Balance: ${balance} ETH`);

      const txs = Promise.allSettled(
        amounts.map(async amount => {
          const weiAmount = ethers.utils.parseEther(amount.toString());
          const value = weiAmount.mul(weiMintPrice).div(ETHER);

          let attempts = 0;
          const txs = [];

          while (attempts < MAX_ATTEMPTS) {
            try {
              const tx = await connection.mint(weiAmount, { value, gasLimit });
              console.log(`Minting ${amount} ${symbol} from ${connection.address} | tx ${tx.hash} sent!`);

              txs.push(tx);
              await tx.wait();

              break;
            } catch (error: any) {
              attempts++;
              const tx = txs[txs.length - 1];

              if (attempts >= MAX_ATTEMPTS) {
                console.log(`Minting tx ${tx ? tx.hash : error.message} failed! | Max attempts reached!`);
                return Promise.reject(error);
              }

              console.log(`Minting tx ${tx ? tx.hash : error.message} failed! | Retrying in ${RETRY_DELAY / 1000}s...`);
              await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
            }
          }

          return txs;
        }),
      );

      return { faucet, txs: (await txs).flat() };
    }),
  );
}

main()
  .then(faucets => {
    console.log("Faucets minting finished!");

    faucets.forEach(({ faucet, txs }, i) => {
      console.log(`Faucet ${i} (${faucet.address}) executed ${txs.length} transactions!`);
    });
  })
  .catch(error => {
    console.error(error);
    process.exitCode = 1;
  });
