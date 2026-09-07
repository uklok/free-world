/*
 * Pre-seeds Hardhat's solc compiler cache.
 *
 * Hardhat 2.17's bundled downloader passes a raw ArrayBuffer to fs.writeFile,
 * which Node rejects (ERR_INVALID_ARG_TYPE), so `hardhat compile` cannot fetch
 * a compiler on a clean machine. This reuses Hardhat's own CompilerDownloader
 * (keccak256 verification, chmod, native-solc check) but injects a download
 * function that writes a proper Buffer, populating the on-disk cache so normal
 * `hardhat compile` runs never touch the broken download path.
 */
const https = require("https");
const fsExtra = require("fs-extra");
const path = require("path");

const {
  CompilerDownloader,
  CompilerPlatform,
} = require("hardhat/internal/solidity/compiler/downloader");
const { getCompilersDir } = require("hardhat/internal/util/global-dir");

function fetchBuffer(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { "User-Agent": "seed-solc-cache" } }, (res) => {
        if (
          res.statusCode &&
          res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.location
        ) {
          if (redirects > 10) return reject(new Error("Too many redirects"));
          res.resume();
          return resolve(fetchBuffer(res.headers.location, redirects + 1));
        }
        if (!res.statusCode || res.statusCode < 200 || res.statusCode > 299) {
          res.resume();
          return reject(new Error(`GET ${url} -> ${res.statusCode}`));
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => resolve(Buffer.concat(chunks)));
      })
      .on("error", reject);
  });
}

async function workingDownload(url, filePath) {
  const data = await fetchBuffer(url);
  await fsExtra.ensureDir(path.dirname(filePath));
  await fsExtra.writeFile(filePath, data);
}

async function main() {
  const version = process.argv[2] || "0.8.20";
  const compilersDir = await getCompilersDir();
  const platform = CompilerDownloader.getCompilerPlatform();

  const downloader = new CompilerDownloader(
    platform,
    compilersDir,
    CompilerDownloader.defaultCompilerListCachePeriod,
    workingDownload
  );

  if (await downloader.isCompilerDownloaded(version)) {
    console.log(`solc ${version} already present in cache (${platform}).`);
    return;
  }

  console.log(`Seeding solc ${version} for platform ${platform}...`);
  await downloader.downloadCompiler(version);

  const compiler = await downloader.getCompiler(version);
  if (compiler === undefined) {
    // Native binary did not run on this host; fall back to the WASM build.
    console.log("Native solc unusable, seeding WASM (solcjs) build instead...");
    const wasmDownloader = new CompilerDownloader(
      CompilerPlatform.WASM,
      compilersDir,
      CompilerDownloader.defaultCompilerListCachePeriod,
      workingDownload
    );
    await wasmDownloader.downloadCompiler(version);
    const wasmCompiler = await wasmDownloader.getCompiler(version);
    if (wasmCompiler === undefined) {
      throw new Error(`Failed to seed a usable solc ${version}`);
    }
    console.log(`Seeded WASM solc ${version} at ${wasmCompiler.compilerPath}`);
    return;
  }

  console.log(`Seeded solc ${version} at ${compiler.compilerPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
