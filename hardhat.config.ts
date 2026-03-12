import { defineConfig } from "hardhat/config";

export default defineConfig({
  solidity: {
    profiles: {
      default: {
        compilers: [{ version: "0.8.23" }],
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
  },
});
