export class NoCryptoWalletError extends Error {
  constructor() {
    super("No crypto wallet found. Please install it.");
  }
}
