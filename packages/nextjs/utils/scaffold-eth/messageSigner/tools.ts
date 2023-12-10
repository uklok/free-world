import { NoCryptoWalletError } from "./errors";
import { BrowserProvider } from "ethers";

export async function signMessage(payload: string | Record<string, any>) {
  if (!window.ethereum) throw new NoCryptoWalletError();
  const provider = new BrowserProvider(window.ethereum);

  const signer = await provider.getSigner();
  const message = typeof payload === "string" ? payload : JSON.stringify(payload);
  const signature = await signer.signMessage(message);

  return { signer: signer.address, message, signature };
}
