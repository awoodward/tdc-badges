 # TDC Badges Smart Contracts and Tests
 The TDC Badges Smart Contracts are a series ERC721A NFT contracts written in Solidity. They differs from a typical NFT smart contracts in that only authorized users with the Minter role can mint NFTs. There also is not withdraw() function because the contract does not receive any ETH payments.

 ## Setup
 To build the contract, you'll need to install Hardhat and some required NPM packages:
 ```
 npm init -Y
 npm i -D hardhat
 npx hardhat
 npm i -D @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
 npm install dotenv
 ```
 You'll also need an Alchemy account to access Ethereum network data.

 Once installed, create a .env file that will contain your environment variables. 
 ```
 touch .env
 code .env
 ```

 Finally, you'll need to install the dependant smart contract libraries:
 ```
 npm install --save-dev @nomiclabs/hardhat-etherscan
 npm install --save-dev erc721a
 npm install @openzeppelin/contracts
 npm install @opengsn/contracts
 ```

 Now that the install and setup is complete, you can make sure everything is installed correctly by running the tests:
 ```
 npx hardhat test
 ```
 
 To deploy the smart contract, run the following command:
 ```
 npx hardhat run scripts/deploy.js --network rinkeby
 ```

 Finally, you can verify the contract with the following command (substitute the address for your newly created contract):
 ```
 npx hardhat verify --network rinkeby {address}
 ```