import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { expect } from "chai"
import { parseUnits } from "ethers"
import { ethers } from "hardhat"

describe("TokenNFTConnector", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let tokenToSwap: ERC20Token
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    let owner: SignerWithAddress
    const amount = parseUnits("10", 18)
    let pairData: TokenNFTConnector.SwapParamsStruct[]
    const contractName = "TokenNFTConnector"
    const contractVersion = "1.2.0"
    const projectOwnerFee = 1000
    const poolFee = 3000

    before(async () => {
        [owner] = await ethers.getSigners()
        const Token = await ethers.getContractFactory("ERC20Token")
        token = await Token.deploy("TEST", "test")
        const SwapRouter = await ethers.getContractFactory("SwapperMock")
        swapRouter = await SwapRouter.deploy(await token.getAddress(), projectOwnerFee)
        const PairToken = await ethers.getContractFactory("ERC20Token")
        tokenToSwap = await PairToken.deploy("USDT", "usdt")
        const DelayVaultProvider = await ethers.getContractFactory("DelayMock")
        delayVaultProvider = await DelayVaultProvider.deploy()
        const TokenNFTConnectorFactory = await ethers.getContractFactory(contractName)
        tokenNFTConnector = (await TokenNFTConnectorFactory.deploy(
            await token.getAddress(),
            await tokenToSwap.getAddress(),
            await swapRouter.getAddress(),
            await delayVaultProvider.getAddress(),
            poolFee,
            `0`
        )) as TokenNFTConnector
        // approve token to swap
        await tokenToSwap.approve(tokenNFTConnector.getAddress(), parseUnits("10000", 18))
        pairData = [{ token: await tokenToSwap.getAddress(), fee: poolFee }]
        await token.transfer(await swapRouter.getAddress(), parseUnits("100000", 18))
    })

    it("should return name of the contract", async () => {
        expect(await tokenNFTConnector.name()).to.equal(contractName)
    })

    it("should return version of the contract", async () => {
        expect(await tokenNFTConnector.version()).to.equal(contractVersion)
    })

    it("should increase delay NFT counter", async () => {
        const currentCounter = await delayVaultProvider.counter()
        await tokenNFTConnector.connect(owner).createLeaderboard(amount, amount * 2n, pairData)
        expect(await delayVaultProvider.counter()).to.equal(BigInt(currentCounter) + 1n)
    })

    it("should increase user delay amount", async () => {
        const user = await ethers.provider.getSigner(1)
        const userAddress = await user.getAddress()
        await tokenToSwap.transfer(userAddress, amount)
        await tokenToSwap.connect(user).approve(await tokenNFTConnector.getAddress(), amount)
        await tokenNFTConnector.connect(user).createLeaderboard(amount, amount * 2n, pairData)
        expect(await delayVaultProvider.ownerToAmount(userAddress)).to.equal(BigInt(amount) * 2n)
    })

    it("should emit event on create leaderboard", async () => {
        const user = await ethers.provider.getSigner(1)
        const userAddress = await user.getAddress()
        await tokenToSwap.transfer(userAddress, amount)
        await tokenToSwap.connect(user).approve(await tokenNFTConnector.getAddress(), amount)
        const tx = await tokenNFTConnector.connect(user).createLeaderboard(amount, amount * 2n, pairData)
        const hashData = await tokenNFTConnector.getBytes(pairData)
        await expect(tx)
            .to.emit(tokenNFTConnector, "LeaderboardCreated")
            .withArgs(userAddress, amount, hashData, amount * 2n)
    })

    it("should revert if no allowance", async () => {
        const user = await ethers.provider.getSigner(2)
        await expect(
            tokenNFTConnector.connect(user).createLeaderboard(amount, amount * 2n, [])
        ).to.be.revertedWithCustomError(tokenNFTConnector, "NoAllowance")
    })

    it("should revert invalid tier swap", async () => {
        await tokenToSwap.connect(owner).approve(await tokenNFTConnector.getAddress(), amount * 10000n)
        await expect(
            tokenNFTConnector.connect(owner).createLeaderboard(amount * 10000n, amount * 2n, pairData)
        ).to.be.revertedWithCustomError(tokenNFTConnector, "UpdateYourTier")
    })

    it("should revert invelid amountOutMinimum", async () => {
        await expect(
            tokenNFTConnector.connect(owner).createLeaderboard(amount, amount * 3n, pairData)
        ).to.be.revertedWithCustomError(tokenNFTConnector, "InsufficientOutputAmount")   
    })

    it("should return true if the level has increased", async () => {
        expect(await tokenNFTConnector.checkIncreaseTier(owner.address, amount * 10000n)).to.equal(true)
    })

    it("should return false if the level doesn't increase", async () => {
        expect(await tokenNFTConnector.checkIncreaseTier(owner.address, amount)).to.equal(false)
    })
})
