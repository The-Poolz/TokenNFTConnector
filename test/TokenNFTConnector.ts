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
    const amount = parseUnits("100", 18)
    let pairData: TokenNFTConnector.SwapParamsStruct[]
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
        const TokenNFTConnectorFactory = await ethers.getContractFactory("TokenNFTConnector")
        tokenNFTConnector = await TokenNFTConnectorFactory.deploy(
            await token.getAddress(),
            await tokenToSwap.getAddress(),
            await swapRouter.getAddress(),
            await delayVaultProvider.getAddress(),
            poolFee,
            `0`
        ) as TokenNFTConnector
        // approve token to swap
        await tokenToSwap.approve(tokenNFTConnector.getAddress(), parseUnits("10000", 18))
        pairData = [{ token: await tokenToSwap.getAddress(), fee: poolFee }]
        await token.transfer(await swapRouter.getAddress(), parseUnits("10000", 18))
    })

    it("should increase delay NFT counter", async () => {
        const currentCounter = await delayVaultProvider.counter()
        await tokenNFTConnector.connect(owner).createLeaderboard(amount, pairData)
        expect(await delayVaultProvider.counter()).to.equal(BigInt(currentCounter) + 1n)
    })

    it("should increase user delay amount", async () => {
        const user = await ethers.provider.getSigner(1)
        const userAddress = await user.getAddress()
        await tokenToSwap.transfer(userAddress, amount)
        await tokenToSwap.connect(user).approve(await tokenNFTConnector.getAddress(), amount)
        await tokenNFTConnector.connect(user).createLeaderboard(amount, pairData)
        expect(await delayVaultProvider.ownerToAmount(userAddress)).to.equal(BigInt(amount) * 2n)
    })

    it("should revert if no allowance", async () => {
        const user = await ethers.provider.getSigner(2)
        await expect(tokenNFTConnector.connect(user).createLeaderboard(amount, [])).to.be.revertedWith(
            "TokenNFTConnector: no allowance"
        )
    })
})
