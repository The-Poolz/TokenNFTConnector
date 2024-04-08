import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { expect } from "chai"
import { parseUnits } from "ethers"
import { ethers } from "hardhat"

describe("Connector Manageable", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let tokenToSwap: ERC20Token
    let owner: SignerWithAddress
    let user: SignerWithAddress
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    const amount = parseUnits("100", 18)
    const projectOwnerFee = parseUnits("1", 17)
    const poolFee = `3000`

    before(async () => {
        [owner, user] = await ethers.getSigners()
        const Token = await ethers.getContractFactory("ERC20Token")
        token = await Token.deploy("TEST", "test")
        const SwapRouter = await ethers.getContractFactory("SwapperMock")
        swapRouter = await SwapRouter.deploy(await token.getAddress(), projectOwnerFee)
        const PairToken = await ethers.getContractFactory("ERC20Token")
        tokenToSwap = await PairToken.deploy("USDT", "usdt")
        const DelayVaultProvider = await ethers.getContractFactory("DelayMock")
        delayVaultProvider = await DelayVaultProvider.deploy()
        await token.transfer(user.address, amount)
        await tokenToSwap.transfer(user.address, amount)
        const transferAmount = parseUnits("10000", 18)
        await token.transfer(await swapRouter.getAddress(), transferAmount)
    })

    beforeEach(async () => {
        const transferAmount = parseUnits("100", 18)
        const TokenNFTConnectorFactory = await ethers.getContractFactory("TokenNFTConnector")
        tokenNFTConnector = await TokenNFTConnectorFactory.deploy(
            await token.getAddress(),
            await tokenToSwap.getAddress(),
            await swapRouter.getAddress(),
            await delayVaultProvider.getAddress(),
            poolFee,
            `0`
        ) as TokenNFTConnector
        await token.approve(await tokenNFTConnector.getAddress(), transferAmount)
        await tokenToSwap.connect(user).approve(await tokenNFTConnector.getAddress(), transferAmount)
    })

    it("should set owner address after creation", async () => {
        const ownerAddress = await tokenNFTConnector.owner()
        const expectedSigner = await ethers.provider.getSigner(0)
        expect(ownerAddress).to.equal(await expectedSigner.getAddress())
    })

    it("should pause contract", async () => {
        await tokenNFTConnector.connect(owner).pause()
        expect(await tokenNFTConnector.paused()).to.equal(true)
        await tokenNFTConnector.connect(owner).unpause()
    })

    it("should unpause contract", async () => {
        await tokenNFTConnector.connect(owner).pause()
        await tokenNFTConnector.connect(owner).unpause()
        expect(await tokenNFTConnector.paused()).to.equal(false)
    })

    it("should set fee amount", async () => {
        await tokenNFTConnector.connect(owner).setProjectOwnerFee(projectOwnerFee)
        expect(await tokenNFTConnector.projectOwnerFee()).to.equal(projectOwnerFee)
    })

    it("should revert if the fee balance is empty", async () => {
        await expect(tokenNFTConnector.connect(owner).withdrawFee()).to.be.rejectedWith(
            "ConnectorManageable: balance is zero"
        )
    })

    it("should pause createLeaderboard", async () => {
        await tokenNFTConnector.connect(owner).pause()
        await expect(tokenNFTConnector.connect(owner).createLeaderboard(amount, amount, [])).to.be.rejectedWith(
            "EnforcedPause()"
        )
    })

    it("owner can't set invalid fee amount", async () => {
        const invalidFee = parseUnits("1", 18)
        await expect(tokenNFTConnector.connect(owner).setProjectOwnerFee(invalidFee)).to.be.rejectedWith(
            "ConnectorManageable: invalid fee"
        )
    })

    it("should return the amount after deducting fee", async () => {
        await tokenNFTConnector.connect(owner).setProjectOwnerFee(projectOwnerFee)
        expect(await tokenNFTConnector.connect(owner).calcMinusFee(amount)).to.equal(parseUnits("90", 18))
    })

    it("withdraw fee", async () => {
        const beforeBalance = await token.balanceOf(owner.address)

        await tokenNFTConnector.setProjectOwnerFee(projectOwnerFee)
        await tokenNFTConnector.connect(user).createLeaderboard(amount, amount, [])
        await tokenNFTConnector.connect(owner).withdrawFee()

        const afterBalance = await token.balanceOf(owner.address)
        // swap ratio is 1:2, 10% fee
        expect(afterBalance).to.equal(BigInt(beforeBalance) + BigInt(parseUnits("20", 18)))
    })
})
