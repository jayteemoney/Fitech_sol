const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EthStaking", function () {
    let FitechToken, EthStaking, fitechToken, ethStaking, owner, user1, user2;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        // Deploy FitechToken
        FitechToken = await ethers.getContractFactory("FitechToken");
        fitechToken = await FitechToken.deploy(owner.address);
        await fitechToken.waitForDeployment();

        // Deploy EthStaking
        EthStaking = await ethers.getContractFactory("EthStaking");
        ethStaking = await EthStaking.deploy(fitechToken.target, owner.address);
        await ethStaking.waitForDeployment();

        // Fund staking contract with FIT tokens
        await fitechToken.connect(owner).mint(owner.address, ethers.parseUnits("10000", 18));
        await fitechToken.connect(owner).approve(ethStaking.target, ethers.parseUnits("10000", 18));
        await ethStaking.connect(owner).fundRewards(ethers.parseUnits("10000", 18));
    });

    it("Should allow staking ETH", async function () {
        await ethStaking.connect(user1).stake({ value: ethers.parseEther("1") });
        const stake = await ethStaking.stakes(user1.address);
        expect(stake.amount).to.equal(ethers.parseEther("1"));
    });

    it("Should allow unstaking and reward calculation", async function () {
        await ethStaking.connect(user1).stake({ value: ethers.parseEther("1") });

        // Fast-forward time (30 days)
        await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await ethStaking.connect(user1).unstake();
        const reward = await ethStaking.rewards(user1.address);
        console.log("Reward calculated:", ethers.formatUnits(reward, 18));
        expect(reward).to.be.closeTo(ethers.parseUnits("10", 18), ethers.parseUnits("0.001", 18));
    });

    it("Should allow claiming rewards", async function () {
        await ethStaking.connect(user1).stake({ value: ethers.parseEther("1") });

        // Fast-forward time
        await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await ethStaking.connect(user1).unstake();
        await ethStaking.connect(user1).claimRewards();

        const balance = await fitechToken.balanceOf(user1.address);
        console.log("User1 FIT balance:", ethers.formatUnits(balance, 18));
        expect(balance).to.be.closeTo(ethers.parseUnits("10", 18), ethers.parseUnits("0.001", 18));
    });
});
