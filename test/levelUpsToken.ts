const { ethers } = require("hardhat");
const { expect } = require("chai");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

describe("Level Ups Token", function () {
    let contract;
    let deployer;
    let initialBalance;

    before(async function () {
        const Contract = await ethers.getContractFactory("LevelUpsToken");
        contract = await Contract.deploy();
        [deployer] = await ethers.getSigners();
    });

    describe("Level 1", function () {
        it("Create Player", async function () {
            await expect(await contract.createPlayer())
                .to.emit(contract, "PlayerCreated")
                .withArgs(deployer, anyValue);
        });

        it("Check Create Duplicate Player", async function () {
            await expect(contract.createPlayer())
                .to.be.reverted;
        });

        it("Check Claim Tokens", async function () {
            await expect(contract.claimTokens())
                .to.be.reverted;
        });

        it("Check Player Balance", async function () {
            initialBalance = await contract.balanceOf(deployer);

            expect(initialBalance)
                .to.equal(175);
        });

        it("Check Player Level", async function () {
            expect(await contract.getPlayerLevel(deployer))
                .to.equal(1);
        });

        it("Afford Player Level Up to 2", async function () {
            expect(await contract.affordLevelUp())
                .to.equal(true);
        });

        it("Player Level Up to 2", async function () {
            await expect(await contract.levelUp())
                .to.emit(contract, "LevelUpgraded")
                .withArgs(deployer, 2, anyValue);
        });
    });

    // Post level-up
    describe("Level 2", function () {
        it("Check Player Balance", async function () {
            let level2Cost = await contract.getLevelCost(2);
            let level2Reward = await contract.getLevelReward(2);

            expect(await contract.balanceOf(deployer))
                .to.equal(initialBalance - level2Cost + level2Reward);
        });

        it("Check Player Level", async function () {
            expect(await contract.getPlayerLevel(deployer))
                .to.equal(2);
        });

        it("Afford Player Level Up to 3", async function () {
            expect(await contract.affordLevelUp())
                .to.equal(false);
        });

        it("Player Level Up to 3", async function () {
            await expect(contract.levelUp())
                .to.be.reverted;
        });
    });
});