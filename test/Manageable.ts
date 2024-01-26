import { SwapperMock, DelayMock } from "../typechain-types"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TokenNFTConnector } from "../typechain-types/contracts/TokenNFTConnector"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Connector Manageable", function () {
    let tokenNFTConnector: TokenNFTConnector
    let token: ERC20Token
    let pairToken: ERC20Token
    let owner: SignerWithAddress
    let swapRouter: SwapperMock
    let delayVaultProvider: DelayMock
    const amount = ethers.utils.parseUnits("100", 18)
    const poolFee = `3000`

    before(async () => {
        ;[owner] = await ethers.getSigners()
        const SwapRouter = (await ethers.deployContract("SwapperMock")) as SwapperMock
        const Token = (await ethers.deployContract("ERC20Token", ["TEST", "test"])) as ERC20Token
        token = await Token.deployed()
        const PairToken = (await ethers.deployContract("ERC20Token", ["USDT", "usdt"])) as ERC20Token
        pairToken = await PairToken.deployed()
        const DelayVaultProvider = (await ethers.deployContract("DelayMock")) as DelayMock
        swapRouter = await SwapRouter.deployed()
        delayVaultProvider = await DelayVaultProvider.deployed()
        tokenNFTConnector = (await ethers.deployContract("TokenNFTConnector", [
            token.address,
            pairToken.address,
            swapRouter.address,
            delayVaultProvider.address,
            poolFee,
            `0`,
        ])) as TokenNFTConnector
        await token.approve(tokenNFTConnector.address, amount.mul(100))
    })

    it("should set owner address after creation", async () => {
        const ownerAddress = await tokenNFTConnector.owner()
        expect(ownerAddress).to.equal(await ethers.provider.getSigner(0).getAddress())
    })

    it("should pause contract", async () => {
        await tokenNFTConnector.connect(owner).pause()
        expect(await tokenNFTConnector.paused()).to.equal(true)
    })

    it("should unpause contract", async () => {
        await tokenNFTConnector.connect(owner).unpause()
        expect(await tokenNFTConnector.paused()).to.equal(false)
    })

    it("should set fee amount", async () => {
        await tokenNFTConnector.connect(owner).setProjectOwnerFee(100)
        expect(await tokenNFTConnector.projectOwnerFee()).to.equal(100)
    })

    it("should revert if the fee balance is empty", async () => {
        await expect(tokenNFTConnector.connect(owner).withdrawFee()).to.be.revertedWith(
            "ConnectorManageable: balance is zero"
        )
    })

    it("should pause createLeaderboard", async () => {
        await tokenNFTConnector.connect(owner).pause()
        await expect(tokenNFTConnector.connect(owner).createLeaderboard("1000", [])).to.be.revertedWith(
            "Pausable: paused"
        )
    })

    it("owner can't set invalid fee amount", async () => {
        await expect(tokenNFTConnector.connect(owner).setProjectOwnerFee(10001)).to.be.revertedWith(
            "ConnectorManageable: invalid fee"
        )
    })

    it("should return the amount after deducting fee", async () => {
        await tokenNFTConnector.connect(owner).setProjectOwnerFee(1000)
        expect(await tokenNFTConnector.connect(owner).calcMinusFee(1000)).to.equal(900)
    })
})
