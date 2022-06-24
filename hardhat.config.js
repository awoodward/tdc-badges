require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      outputSelection: {
        "*": {
          "*": ["storageLayout",
            "evm.bytecode",
            "evm.deployedBytecode",
            "abi"
          ]
        }
      },
    },
  },
  networks: {
    rinkeby: {
      url: `${process.env.ALCHEMY_RINKEBY_URL}`,
      accounts: [`0x${process.env.RINKEBY_PRIVATE_KEY}`]
    },
    mainnet: {
      url: `${process.env.ALCHEMY_MAINNET_URL}`,
      accounts: [`0x${process.env.MAINNET_PRIVATE_KEY}`]
    },
    polygon: {
      url: `${process.env.ALCHEMY_POLYGON_URL}`,
      accounts: [`0x${process.env.RINKEBY_PRIVATE_KEY}`]
    },
    arbitrumtest: {
      url: `${process.env.ARBITRUM_TEST_URL}`,
      accounts: [`0x${process.env.RINKEBY_PRIVATE_KEY}`]
    },
    arbitrummain: {
      url: `${process.env.ALCHEMY_ARBITRUM_URL}`,
      accounts: [`0x${process.env.MAINNET_PRIVATE_KEY}`]
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      arbitrumTestnet: `${process.env.ETHERSCAN_ARBITRUM_TEST}`,
      arbitrumOne: `${process.env.ETHERSCAN_ARBITRUM_ONE}`,
      rinkeby:  `${process.env.ETHERSCAN_RINKEBY}`
    } // Arbiscan
  }
};
