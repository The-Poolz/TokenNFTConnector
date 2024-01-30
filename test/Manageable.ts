import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Connector Manageable", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let tokenToSwap: ERC20Token
    let owner: SignerWithAddress
    let user: SignerWithAddress
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    const amount = ethers.utils.parseUnits("100", 18)
    const projectOwnerFee = 1000
    const poolFee = `3000`

    before(async () => {
        [owner, user] = await ethers.getSigners()
        const Token = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        token = await Token.deployed()
        const SwapRouter = (await ethers.deployContract("SwapperMock", [token.address])) as SwapperMock
        const PairToken = (await ethers.deployContract("ERC20Token", ["USDT", "usdt"])) as ERC20Token
        tokenToSwap = await PairToken.deployed()
        const DelayVaultProvider = (await ethers.deployContract("DelayMock")) as DelayMock
        swapRouter = await SwapRouter.deployed()
        delayVaultProvider = await DelayVaultProvider.deployed()
        await token.transfer(user.address, amount)
        await tokenToSwap.transfer(user.address, amount)
        await token.transfer(swapRouter.address, amount.mul(99))
    })

    beforeEach(async () => {
        tokenNFTConnector = (await ethers.deployContract("TokenNFTConnector", [
            token.address,
            tokenToSwap.address,
            swapRouter.address,
            delayVaultProvider.address,
            poolFee,
            `0`,
        ])) as TokenNFTConnector
        await token.approve(tokenNFTConnector.address, amount.mul(100))
        await tokenToSwap.connect(user).approve(tokenNFTConnector.address, amount.mul(100))
    })

    it("should set owner address after creation", async () => {
        const ownerAddress = await tokenNFTConnector.owner()
        expect(ownerAddress).to.equal(await ethers.provider.getSigner(0).getAddress())
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
        await expect(tokenNFTConnector.connect(owner).withdrawFee()).to.be.revertedWith(
            "ConnectorManageable: balance is zero"
        )
    })

    it("should pause createLeaderboard", async () => {
        await tokenNFTConnector.connect(owner).pause()
        await expect(tokenNFTConnector.connect(owner).createLeaderboard(amount, [])).to.be.revertedWith(
            "Pausable: paused"
        )
    })

    it("owner can't set invalid fee amount", async () => {
        const invalidFee = 10001
        await expect(tokenNFTConnector.connect(owner).setProjectOwnerFee(invalidFee)).to.be.revertedWith(
            "ConnectorManageable: invalid fee"
        )
    })

    it("should return the amount after deducting fee", async () => {
        await tokenNFTConnector.connect(owner).setProjectOwnerFee(projectOwnerFee)
        expect(await tokenNFTConnector.connect(owner).calcMinusFee(projectOwnerFee)).to.equal(900)
    })

    it("withdraw fee", async () => {
        const beforeBalance = await token.balanceOf(owner.address)

        await tokenNFTConnector.setProjectOwnerFee(projectOwnerFee)
        await tokenNFTConnector.connect(user).createLeaderboard(amount, [])
        await tokenNFTConnector.connect(owner).withdrawFee()

        const afterBalance = await token.balanceOf(owner.address)
        expect(afterBalance).to.equal(beforeBalance.add(amount.mul(2).div(10)))
    })
})
