const { expect } = require("chai");
const { ethers } = require("hardhat");
//const { beforeEach } = require("mocha"); *** Don't use this when using Chai and Hardhat
const { Contract, BigNumber } = require("ethers");
const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");
const { delay } = require("bluebird");
const { parseEther, getAddress } = ethers.utils;

describe("TDC Collectibles", () => {
    let collectiblesContract;
    let owner;
    let address1;
    let address2;
    let address3;

    beforeEach(async () => {
        const CollectiblesFactory = await ethers.getContractFactory(
            "TDCCollectibles"
        );
        [owner, address1, address2, address3] = await ethers.getSigners();
        collectiblesContract = await CollectiblesFactory.deploy(
        );
    });

    it("Should initialize the Collectibles contract", async () => {
        expect(await collectiblesContract.totalSupply()).to.equal(0);
    });

    it("Should give away collectibles", async () => {
        const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
        console.log(MINTER_ROLE)
        let tokenId = await collectiblesContract.totalSupply();

        // Test Mint permissions
        await expect(collectiblesContract.safeMint(address1.address))
            .to.be.revertedWith("Only addresses with minter role can perform this action.");
        // Grant Minter Role
        await collectiblesContract.grantRole(MINTER_ROLE, owner.address);
        // Mint to address 1
        expect(
            await collectiblesContract.safeMint(address1.address)
        )
            .to.emit(collectiblesContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address1.address, tokenId);
        // Transfer to address 2
        expect(
            await collectiblesContract.connect(address1).transferFrom(address1.address, address2.address, tokenId)
        )
            .to.emit(collectiblesContract, "Transfer")
            .withArgs(address1.address, address2.address, tokenId);

        tokenId++
        // Mint to address 2
        expect(
            await collectiblesContract.safeMint(address2.address)
        )
            .to.emit(collectiblesContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address2.address, tokenId);

        // test out of bounds token
        await expect(collectiblesContract.tokenURI(tokenId + 1))
            .to.be.revertedWith("Collectible token does not exist");

        // Test default URI
        expect(await collectiblesContract.tokenURI(1)).to.equal("");
        // change base URI and try again
        await collectiblesContract.setBaseURI("foo/");
        expect(await collectiblesContract.tokenURI(1)).to.equal("foo/1.json");
        // Test default contract URI
        expect(await collectiblesContract.contractURI()).to.equal("");
        // Test contract metadata URI:
        await collectiblesContract.setContractURI("foobar.json");
        expect(await collectiblesContract.contractURI()).to.equal("foobar.json");
    });
});