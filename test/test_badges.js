const { expect } = require("chai");
const { ethers } = require("hardhat");
//const { beforeEach } = require("mocha"); *** Don't use this when using Chai and Hardhat
const { Contract, BigNumber } = require("ethers");
const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");
const { delay } = require("bluebird");
const { parseEther, getAddress } = ethers.utils;

describe("TDC Badge", () => {
    let badgeContract;
    let owner;
    let address1;
    let address2;
    let address3;

    beforeEach(async () => {
        const BadgeFactory = await ethers.getContractFactory(
            "TDCBadges"
        );
        [owner, address1, address2, address3] = await ethers.getSigners();
        badgeContract = await BadgeFactory.deploy();
    });

    it("Should initialize the Badge contract", async () => {
        expect(await badgeContract.totalSupply()).to.equal(0);
        // Check ERC721 Interface
        expect(await badgeContract.supportsInterface(0x80ac58cd)).to.equal(true);
    });

    it("Should give away badges", async () => {
        const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
        let tokenId = await badgeContract.totalSupply();

        // Test Mint permissions
        await expect(badgeContract.safeMint(address1.address))
            .to.be.revertedWith("Only addresses with minter role can perform this action.");
        // Grant Minter Role
        await badgeContract.grantRole(MINTER_ROLE, owner.address);
        await expect(badgeContract.mintBadges(address1.address, 0))
            .to.be.revertedWith("Incorrect number of badges.");

        // Mint to address 1
        expect(
            await badgeContract.safeMint(address1.address)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address1.address, tokenId);
        tokenId++
        // Mint to address 2
        expect(
            await badgeContract.safeMint(address2.address)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address2.address, tokenId);

        // test out of bounds token
        await expect(badgeContract.tokenURI(tokenId + 1))
            .to.be.revertedWith("Badge token does not exist");

        // Test default URI
        expect(await badgeContract.tokenURI(1)).to.equal("");
        // change base URI and try again
        await badgeContract.setBaseURI("foo/");
        expect(await badgeContract.tokenURI(1)).to.equal("foo/1.json");
        // Test default contract URI
        expect(await badgeContract.contractURI()).to.equal("");
        // Test contract metadata URI:
        await badgeContract.setContractURI("foobar.json");
        expect(await badgeContract.contractURI()).to.equal("foobar.json");
    });

    it("Should transfer badges", async () => {
        const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
        // Grant Minter Role
        await badgeContract.grantRole(MINTER_ROLE, owner.address);
        // Mint to address 1
        expect(
            await badgeContract.safeMint(address1.address)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address1.address, 0);
        // Transfer to address 2 - fail
        await expect(badgeContract.connect(address1).transferFrom(address1.address, address2.address, 0))
            .to.be.revertedWith("Collectibles contract address not set.");

        // Create Collectibles contract
        const CollectiblesFactory = await ethers.getContractFactory(
            "TDCCollectibles"
        );
        collectiblesContract = await CollectiblesFactory.deploy();

        await collectiblesContract.grantRole(MINTER_ROLE, badgeContract.address);

        // Set Collectibles contract address
        await badgeContract.setCollectiblesContractAddress(collectiblesContract.address);
        // Transfer to address 2 - succeed
        expect(
            await badgeContract.connect(address1).transferFrom(address1.address, address2.address, 0)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(address1.address, address2.address, 0);
        // Transfer to address 3 - fail
        await expect(badgeContract.connect(address2).transferFrom(address2.address, address3.address, 0))
            .to.be.revertedWith("Badges can only be transferred once.");
    });
    it("Should redeem for coins", async () => {
        const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
        // Grant Minter Role
        await badgeContract.grantRole(MINTER_ROLE, owner.address);
        // Mint to address 1
        expect(
            await badgeContract.safeMint(address1.address)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(ethers.constants.AddressZero, address1.address, 0);
        // Create Collectibles contract
        const CollectiblesFactory = await ethers.getContractFactory(
            "TDCCollectibles"
        );
        collectiblesContract = await CollectiblesFactory.deploy();

        await collectiblesContract.grantRole(MINTER_ROLE, badgeContract.address);

        // Set Collectibles contract address
        await badgeContract.setCollectiblesContractAddress(collectiblesContract.address);

        // Redeem - fail
        await expect(badgeContract.connect(address2).redeemToken(address2.address, 0))
            .to.be.revertedWith("Badge must be transferred before it can be redeemed.");

        // Transfer to address 2 - succeed
        expect(
            await badgeContract.connect(address1).transferFrom(address1.address, address2.address, 0)
        )
            .to.emit(badgeContract, "Transfer")
            .withArgs(address1.address, address2.address, 0);

        // Redeem - fail
        await expect(badgeContract.connect(address2).redeemToken(address2.address, 0))
            .to.be.revertedWith("Coins contract address not set.");

        // Create Collectibles contract
        const CoinsFactory = await ethers.getContractFactory(
            "TDCCoins"
        );
        coinsContract = await CoinsFactory.deploy();

        // Set Coins contract address
        await badgeContract.setCoinsContractAddress(coinsContract.address);

        // Redeem - fail
        await expect(badgeContract.connect(address2).redeemToken(address2.address, 0))
            .to.be.revertedWith("Only addresses with minter role can perform this action.");

        await coinsContract.grantRole(MINTER_ROLE, badgeContract.address);

        await expect(badgeContract.connect(address2).redeemToken(address2.address, 0))
        .to.emit(badgeContract, "Transfer")
        .withArgs(address2.address, ethers.utils.getAddress("0x0000000000000000000000000000000000000000"), 0);

        // Check coins balance
        expect(await coinsContract.balanceOf(address2.address)).to.equal(1);

    });
});