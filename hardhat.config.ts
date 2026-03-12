import { defineConfig } from "hardhat/config";

export default defineConfig({
  solidity: {
    profiles: {
      default: {
        compilers: [
          {
            version: "0.8.23",
            settings: {
              optimizer: {
                enabled: true,
                runs: 1_000_000,
              },
              evmVersion: "shanghai",
              viaIR: true,
            },
          },
        ],
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
  },
});
